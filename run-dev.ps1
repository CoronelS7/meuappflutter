param(
  [string]$PublishableKey,
  [string]$BackendUrl,
  [switch]$ShowConfigOnly,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$FlutterArgs = @($FlutterArgs)

function Get-ItemCount {
  param([object]$Value)

  return @($Value).Count
}

function Get-LaunchDefines {
  param([string]$LaunchFilePath)

  $defines = @{}

  if (-not (Test-Path $LaunchFilePath)) {
    return $defines
  }

  $launchConfig = Get-Content $LaunchFilePath -Raw | ConvertFrom-Json
  foreach ($configuration in $launchConfig.configurations) {
    $toolArgs = @($configuration.toolArgs)

    for ($index = 0; $index -lt $toolArgs.Count; $index++) {
      if ($toolArgs[$index] -ne '--dart-define' -or $index + 1 -ge $toolArgs.Count) {
        continue
      }

      $pair = $toolArgs[$index + 1]
      if ($pair -match '^(?<key>[^=]+)=(?<value>.*)$') {
        if (-not $defines.ContainsKey($matches.key)) {
          $defines[$matches.key] = $matches.value
        }
      }
    }
  }

  return $defines
}

function Get-PortFromUrl {
  param([string]$Url)

  try {
    $uri = [System.Uri]$Url
    if ($uri.Port -gt 0) {
      return $uri.Port
    }
  }
  catch {
  }

  return 4242
}

function Test-PortListening {
  param([int]$Port)

  $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
  return $null -ne $connections
}

function Test-BackendHealth {
  param([string]$HealthUrl)

  try {
    $response = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 2
    return $response.ok -eq $true
  }
  catch {
    return $false
  }
}

function Wait-BackendHealth {
  param(
    [string]$HealthUrl,
    [int]$TimeoutSeconds = 20,
    [int]$IntervalMilliseconds = 1000
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

  while ((Get-Date) -lt $deadline) {
    if (Test-BackendHealth $HealthUrl) {
      return $true
    }

    Start-Sleep -Milliseconds $IntervalMilliseconds
  }

  return $false
}

function Test-BackendSecretConfigured {
  param([string]$EnvFilePath)

  if (-not [string]::IsNullOrWhiteSpace($env:STRIPE_SECRET_KEY)) {
    return $true
  }

  if (-not (Test-Path $EnvFilePath)) {
    return $false
  }

  $lines = Get-Content $EnvFilePath
  foreach ($line in $lines) {
    if ($line -match '^\s*STRIPE_SECRET_KEY\s*=\s*(.+?)\s*$') {
      return -not [string]::IsNullOrWhiteSpace($matches[1])
    }
  }

  return $false
}

$projectRoot = Split-Path -Parent $PSCommandPath
$backendDir = Join-Path $projectRoot 'backend'
$backendEnvFile = Join-Path $backendDir '.env'
$launchFilePath = Join-Path $projectRoot '.vscode\launch.json'
$launchDefines = Get-LaunchDefines -LaunchFilePath $launchFilePath

if ([string]::IsNullOrWhiteSpace($PublishableKey)) {
  $PublishableKey = $env:STRIPE_PUBLISHABLE_KEY
}
if ([string]::IsNullOrWhiteSpace($PublishableKey) -and $launchDefines.ContainsKey('STRIPE_PUBLISHABLE_KEY')) {
  $PublishableKey = $launchDefines['STRIPE_PUBLISHABLE_KEY']
}

if ([string]::IsNullOrWhiteSpace($BackendUrl)) {
  $BackendUrl = $env:STRIPE_BACKEND_URL
}
if ([string]::IsNullOrWhiteSpace($BackendUrl) -and $launchDefines.ContainsKey('STRIPE_BACKEND_URL')) {
  $BackendUrl = $launchDefines['STRIPE_BACKEND_URL']
}
if ([string]::IsNullOrWhiteSpace($BackendUrl)) {
  $BackendUrl = 'http://10.0.2.2:4242'
}

if ([string]::IsNullOrWhiteSpace($PublishableKey)) {
  throw 'STRIPE_PUBLISHABLE_KEY nao encontrada. Defina no launch.json, no ambiente, ou passe -PublishableKey.'
}

$backendPort = Get-PortFromUrl $BackendUrl
$healthUrl = "http://localhost:$backendPort/health"
$stdoutLog = Join-Path $backendDir 'backend.stdout.log'
$stderrLog = Join-Path $backendDir 'backend.stderr.log'
$backendProcess = $null
$startedBackend = $false

if ($ShowConfigOnly) {
  Write-Host "PublishableKey: $PublishableKey"
  Write-Host "BackendUrl: $BackendUrl"
  Write-Host "HealthUrl: $healthUrl"
  exit 0
}

if (-not (Test-Path $backendDir)) {
  throw "Diretorio backend nao encontrado em $backendDir."
}

if (-not (Test-BackendSecretConfigured $backendEnvFile)) {
  throw "STRIPE_SECRET_KEY nao encontrada. Crie backend/.env a partir de backend/.env.example ou defina a variavel de ambiente STRIPE_SECRET_KEY."
}

if (-not (Test-Path (Join-Path $backendDir 'node_modules'))) {
  Push-Location $backendDir
  try {
    & npm.cmd install
    if ($LASTEXITCODE -ne 0) {
      throw 'npm install falhou no backend.'
    }
  }
  finally {
    Pop-Location
  }
}

if (Test-BackendHealth $healthUrl) {
  Write-Host "Backend ja estava ativo em $healthUrl. Reutilizando processo existente."
}
elseif (Test-PortListening $backendPort) {
  throw "A porta $backendPort esta ocupada, mas /health nao respondeu como backend Stripe."
}
else {
  $backendProcess = Start-Process `
    -FilePath 'node' `
    -ArgumentList 'server.js' `
    -WorkingDirectory $backendDir `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru

  $startedBackend = $true

  if ($backendProcess.HasExited) {
    throw "Backend encerrou ao iniciar. Veja $stdoutLog e $stderrLog."
  }

  if (-not (Wait-BackendHealth -HealthUrl $healthUrl -TimeoutSeconds 25)) {
    if (-not $backendProcess.HasExited) {
      Stop-Process -Id $backendProcess.Id -Force
    }

    throw "Backend nao respondeu em $healthUrl. Veja $stdoutLog e $stderrLog."
  }

  Write-Host "Backend iniciado em background. Logs: $stdoutLog"
}

$flutterCommandArgs = @(
  'run'
  "--dart-define=STRIPE_PUBLISHABLE_KEY=$PublishableKey"
  "--dart-define=STRIPE_BACKEND_URL=$BackendUrl"
)

if ((Get-ItemCount $FlutterArgs) -gt 0) {
  $flutterCommandArgs += $FlutterArgs
}

$flutterExitCode = 0

try {
  & flutter.bat @flutterCommandArgs
  $flutterExitCode = $LASTEXITCODE
}
finally {
  if ($startedBackend -and $backendProcess -and -not $backendProcess.HasExited) {
    Stop-Process -Id $backendProcess.Id -Force
  }
}

exit $flutterExitCode
