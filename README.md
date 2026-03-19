# Pedido Facil

Integracao Stripe adaptada ao fluxo atual do app Flutter, preservando a UI existente de carrinho, perfil e pagamentos.

## O que foi integrado

- Checkout por cartao com `flutter_stripe` e `PaymentSheet`
- Checkout por Google Pay no Android com `flutter_stripe`
- Backend Node/Express para criar `PaymentIntent`
- Opcao de salvar cartao para proximas compras no carrinho
- Tela `Pagamentos` com lista de cartoes salvos e badge `Padrao`
- Botao `Adicionar cartao` abrindo o `CustomerSheet`
- Script `run-dev.ps1` para subir backend + `flutter run`

## Configuracao

1. Flutter:
   - preencha `STRIPE_PUBLISHABLE_KEY` em [.vscode/launch.json](/c:/Users/chico/OneDrive/Desktop/PedidoFacil/meuappflutter/.vscode/launch.json) ou na variavel de ambiente
   - `STRIPE_BACKEND_URL` padrao do Android emulator: `http://10.0.2.2:4242`
   - opcionais para Google Pay:
     - `STRIPE_GOOGLE_PAY_COUNTRY_CODE=BR`
     - `STRIPE_GOOGLE_PAY_CURRENCY_CODE=BRL`
     - `STRIPE_GOOGLE_PAY_TEST_ENV=true` para forcar ambiente de teste
2. Backend:
   - copie `backend/.env.example` para `backend/.env`
   - defina `STRIPE_SECRET_KEY` somente em `backend/.env`
   - mantenha `HOST=0.0.0.0` para aceitar conexoes do celular na mesma rede

## Rodando

Uma vez:

```powershell
cd backend
npm install
cd ..
flutter pub get
```

No Android emulator:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-dev.ps1
```

No celular Android na mesma rede Wi-Fi:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-dev.ps1 -UseLocalIp -d <device_id>
```

O script:

- le `STRIPE_PUBLISHABLE_KEY` e `STRIPE_BACKEND_URL` do `launch.json` ou do ambiente
- quando usado com `-UseLocalIp`, detecta um IPv4 local e monta o `STRIPE_BACKEND_URL` para o celular
- reutiliza backend existente se `http://localhost:4242/health` responder
- sobe o backend automaticamente quando necessario
- roda `flutter run` com os `--dart-define` corretos

Se precisar sobrescrever a URL ou passar argumentos extras do Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-dev.ps1 -BackendUrl http://10.0.2.2:4242 -d emulator-5554
```

## Fluxo atual

1. No carrinho, escolha `Cartao` ou `Google Pay` em `Metodo Pagamento`
2. Em `Cartao`, marque `Salvar cartao para proximas compras` se desejar
3. Toque em `Finalizar Pedido`
4. `Cartao` abre o `PaymentSheet`; `Google Pay` abre a carteira do Google no Android suportado
5. Em `Perfil > Pagamentos`, veja os cartoes salvos e use `Adicionar cartao`

## Backend

Endpoints principais:

- `GET /health`
- `POST /create-payment-intent`
- `GET /payment-methods?customerKey=...`
- `POST /customer-sheet`

O backend salva localmente o mapeamento entre `customerKey` do app e `customerId` da Stripe em `backend/customer-store.json`.
