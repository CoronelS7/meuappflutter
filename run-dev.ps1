param(
  [string]$PublishableKey,
  [string]$BackendUrl,
  [string]$DeviceId,
  [switch]$BackendOnly,
  [switch]$UseLocalIp,
  [switch]$SkipLocalBackend,
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

function Test-IsPublishableKeyValid {
  param([string]$Key)

  if ([string]::IsNullOrWhiteSpace($Key)) {
    return $false
  }

  $normalized = $Key.Trim()
  if (
    -not $normalized.StartsWith('pk_test_') -and
    -not $normalized.StartsWith('pk_live_')
  ) {
    return $false
  }

  if ($normalized.Length -lt 32) {
    return $false
  }

  $lower = $normalized.ToLowerInvariant()
  $placeholderTokens = @(
    'sua_chave',
    'cole_sua',
    'placeholder',
    'your_key',
    'yourkey',
    'example',
    'xxxx'
  )

  foreach ($token in $placeholderTokens) {
    if ($lower.Contains($token)) {
      return $false
    }
  }

  return $true
}

function Get-MaskedPublishableKey {
  param([string]$Key)

  if ([string]::IsNullOrWhiteSpace($Key)) {
    return '(vazia)'
  }

  $normalized = $Key.Trim()
  if ($normalized.Length -le 18) {
    return $normalized
  }

  $start = $normalized.Substring(0, 12)
  $end = $normalized.Substring($normalized.Length - 6, 6)
  return "$start...$end (len $($normalized.Length))"
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

function Test-IsEmulatorDeviceId {
  param([string]$Id)

  if ([string]::IsNullOrWhiteSpace($Id)) {
    return $false
  }

  return (
    $Id -like 'emulator-*' -or
    $Id -like 'localhost:*' -or
    $Id -like '127.0.0.1:*'
  )
}

function Test-IsEmulatorBackendUrl {
  param([string]$Url)

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return $false
  }

  try {
    $uri = [System.Uri]$Url
    return (
      $uri.Host -eq '10.0.2.2' -or
      $uri.Host -eq '127.0.0.1' -or
      $uri.Host -eq 'localhost'
    )
  }
  catch {
    return $false
  }
}

function Get-LocalIPv4Addresses {
  $allIps = New-Object System.Collections.Generic.HashSet[string]

  $systemIps = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -notlike '127.*' -and
      $_.IPAddress -notlike '169.254.*'
    }

  foreach ($ip in $systemIps) {
    if (-not [string]::IsNullOrWhiteSpace($ip.IPAddress)) {
      $null = $allIps.Add($ip.IPAddress)
    }
  }

  $ipconfigOutput = ipconfig 2>$null
  foreach ($line in $ipconfigOutput) {
    if ($line -match 'IPv4[^:]*:\s*(?<ip>\d+\.\d+\.\d+\.\d+)') {
      $null = $allIps.Add($matches.ip)
    }
  }

  return @($allIps)
}

function Test-IsLocalMachineBackendUrl {
  param([string]$Url)

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return $true
  }

  try {
    $uri = [System.Uri]$Url
    $uriHost = $uri.Host.ToLowerInvariant()

    if (
      $uriHost -eq 'localhost' -or
      $uriHost -eq '127.0.0.1' -or
      $uriHost -eq '10.0.2.2'
    ) {
      return $true
    }

    $localIps = Get-LocalIPv4Addresses
    return $localIps -contains $uri.Host
  }
  catch {
    return $false
  }
}

function Get-LocalIPv4Address {
  function Is-PrivateIPv4 {
    param([string]$IpAddress)

    return (
      $IpAddress -like '10.*' -or
      $IpAddress -like '192.168.*' -or
      $IpAddress -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.'
    )
  }

  function Is-VirtualOrVpnInterface {
    param([string]$Alias)

    if ([string]::IsNullOrWhiteSpace($Alias)) {
      return $false
    }

    return $Alias -match '(?i)(vpn|openvpn|tap|tun|vethernet|virtual|hyper-v|loopback|radmin)'
  }

  $preferredIps = New-Object System.Collections.Generic.List[string]
  $fallbackGatewayIps = New-Object System.Collections.Generic.List[string]
  $privateIps = New-Object System.Collections.Generic.List[string]
  $otherIps = New-Object System.Collections.Generic.List[string]

  function Add-Ipv4Candidate {
    param([string]$IpAddress)

    if ([string]::IsNullOrWhiteSpace($IpAddress)) {
      return
    }

    if ($IpAddress -like '127.*' -or $IpAddress -like '169.254.*') {
      return
    }

    if (
      $IpAddress -like '10.*' -or
      $IpAddress -like '192.168.*' -or
      $IpAddress -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.'
    ) {
      $privateIps.Add($IpAddress)
      return
    }

    $otherIps.Add($IpAddress)
  }

  $ipConfigs = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
    Where-Object {
      $null -ne $_.IPv4DefaultGateway -and
      $null -ne $_.IPv4Address
    }

  foreach ($config in $ipConfigs) {
    $alias = $config.InterfaceAlias
    $targetList = $fallbackGatewayIps
    if (-not (Is-VirtualOrVpnInterface -Alias $alias)) {
      $targetList = $preferredIps
    }

    foreach ($ipEntry in @($config.IPv4Address)) {
      $ip = $ipEntry.IPAddress
      if ([string]::IsNullOrWhiteSpace($ip)) {
        continue
      }

      if ($ip -like '127.*' -or $ip -like '169.254.*') {
        continue
      }

      if (Is-PrivateIPv4 -IpAddress $ip) {
        $targetList.Add($ip)
      }
    }
  }

  if ($preferredIps.Count -gt 0) {
    return $preferredIps[0]
  }

  if ($fallbackGatewayIps.Count -gt 0) {
    return $fallbackGatewayIps[0]
  }

  $candidates = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
      $_.IPAddress -notlike '127.*' -and
      $_.IPAddress -notlike '169.254.*' -and
      $_.PrefixOrigin -ne 'WellKnown'
    } |
    Sort-Object InterfaceIndex, SkipAsSource

  foreach ($candidate in $candidates) {
    Add-Ipv4Candidate -IpAddress $candidate.IPAddress
  }

  $ipconfigOutput = ipconfig 2>$null
  foreach ($line in $ipconfigOutput) {
    if ($line -match 'IPv4[^:]*:\s*(?<ip>\d+\.\d+\.\d+\.\d+)') {
      Add-Ipv4Candidate -IpAddress $matches.ip
    }
  }

  if ($privateIps.Count -gt 0) {
    return $privateIps[0]
  }

  if ($otherIps.Count -gt 0) {
    return $otherIps[0]
  }

  return $null
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

if ([string]::IsNullOrWhiteSpace($PublishableKey) -and $launchDefines.ContainsKey('STRIPE_PUBLISHABLE_KEY')) {
  $PublishableKey = $launchDefines['STRIPE_PUBLISHABLE_KEY']
}
if ([string]::IsNullOrWhiteSpace($PublishableKey)) {
  $PublishableKey = $env:STRIPE_PUBLISHABLE_KEY
}

if ([string]::IsNullOrWhiteSpace($BackendUrl)) {
  $BackendUrl = $env:STRIPE_BACKEND_URL
}
if ([string]::IsNullOrWhiteSpace($BackendUrl) -and $launchDefines.ContainsKey('STRIPE_BACKEND_URL')) {
  $BackendUrl = $launchDefines['STRIPE_BACKEND_URL']
}

if ($UseLocalIp -and -not $PSBoundParameters.ContainsKey('BackendUrl')) {
  $localIp = Get-LocalIPv4Address
  if ([string]::IsNullOrWhiteSpace($localIp)) {
    throw 'Nao foi possivel detectar um IPv4 local para usar no celular.'
  }

  $BackendUrl = "http://${localIp}:4242"
  Write-Host "Usando IP local detectado: $localIp"
}

$devicePareceFisico = (
  -not [string]::IsNullOrWhiteSpace($DeviceId) -and
  -not (Test-IsEmulatorDeviceId -Id $DeviceId)
)
$backendUrlFoiInformadaManualmente = $PSBoundParameters.ContainsKey('BackendUrl')
$backendApontaParaEmulador = Test-IsEmulatorBackendUrl -Url $BackendUrl

if (
  -not $UseLocalIp -and
  -not $backendUrlFoiInformadaManualmente -and
  ([string]::IsNullOrWhiteSpace($BackendUrl) -or $backendApontaParaEmulador) -and
  $devicePareceFisico
) {
  $localIp = Get-LocalIPv4Address
  if (-not [string]::IsNullOrWhiteSpace($localIp)) {
    $backendPort = if ([string]::IsNullOrWhiteSpace($BackendUrl)) {
      4242
    } else {
      Get-PortFromUrl $BackendUrl
    }

    $BackendUrl = "http://${localIp}:$backendPort"
    Write-Host "Dispositivo fisico detectado. Usando IP local automaticamente: $localIp"
  }
}

if ([string]::IsNullOrWhiteSpace($BackendUrl)) {
  $BackendUrl = 'http://10.0.2.2:4242'
}

if ([string]::IsNullOrWhiteSpace($PublishableKey)) {
  throw 'STRIPE_PUBLISHABLE_KEY nao encontrada. Defina no launch.json, no ambiente, ou passe -PublishableKey.'
}

if (-not (Test-IsPublishableKeyValid -Key $PublishableKey)) {
  $maskedKey = Get-MaskedPublishableKey -Key $PublishableKey
  throw "STRIPE_PUBLISHABLE_KEY invalida: $maskedKey. Use uma chave publica real da Stripe (pk_test_... ou pk_live_...)."
}

$backendEhLocal = Test-IsLocalMachineBackendUrl -Url $BackendUrl
$shouldManageLocalBackend = -not $SkipLocalBackend -and $backendEhLocal

$backendPort = Get-PortFromUrl $BackendUrl
$healthUrl = "http://127.0.0.1:$backendPort/health"
$stdoutLog = Join-Path $backendDir 'backend.stdout.log'
$stderrLog = Join-Path $backendDir 'backend.stderr.log'
$backendProcess = $null
$startedBackend = $false

if ($ShowConfigOnly) {
  Write-Host "PublishableKey: $(Get-MaskedPublishableKey -Key $PublishableKey)"
  Write-Host "BackendUrl: $BackendUrl"
  Write-Host "BackendLocalMode: $shouldManageLocalBackend"
  if ($shouldManageLocalBackend) {
    Write-Host "HealthUrl: $healthUrl"
  }
  exit 0
}

if ($shouldManageLocalBackend) {
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
}
else {
  Write-Host "Usando backend remoto em $BackendUrl. O script nao vai iniciar backend local."
}

$keepBackendRunning = $BackendOnly -and $shouldManageLocalBackend

if ($BackendOnly) {
  if ($shouldManageLocalBackend) {
    Write-Host "Backend pronto para o app em $BackendUrl"
  }
  else {
    Write-Host "Nenhum backend local foi iniciado. O app vai usar $BackendUrl"
  }
  exit 0
}

$flutterCommandArgs = @(
  'run'
  "--dart-define=STRIPE_PUBLISHABLE_KEY=$PublishableKey"
  "--dart-define=STRIPE_BACKEND_URL=$BackendUrl"
)

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
  $flutterCommandArgs += @('-d', $DeviceId)
}

if ((Get-ItemCount $FlutterArgs) -gt 0) {
  $flutterCommandArgs += $FlutterArgs
}

$flutterExitCode = 0

try {
  & flutter.bat @flutterCommandArgs
  $flutterExitCode = $LASTEXITCODE
}
finally {
  if (
    -not $keepBackendRunning -and
    $startedBackend -and
    $backendProcess -and
    -not $backendProcess.HasExited
  ) {
    Stop-Process -Id $backendProcess.Id -Force
  }
}

exit $flutterExitCode
