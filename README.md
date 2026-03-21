# Pedido Facil

Integracao Stripe do app Flutter com backend em Firebase Functions (Cloud Functions v2), funcionando por URL HTTPS publica em qualquer rede.

## O que foi integrado

- Checkout por cartao com `flutter_stripe` e `PaymentSheet`
- Checkout por Google Pay no Android com `flutter_stripe`
- API Stripe em `Firebase Functions` (funcao `stripeApi`)
- Opcao de salvar cartao para proximas compras no carrinho
- Tela `Pagamentos` com lista de cartoes salvos e badge `Padrao`
- Botao `Adicionar cartao` abrindo o `CustomerSheet`
- Script `run-dev.ps1` para desenvolvimento local opcional

## Arquitetura atual

- Function: `stripeApi`
- Regiao: `southamerica-east1` (Sao Paulo)
- URL base publica:
  - `https://southamerica-east1-ecommerce-40890.cloudfunctions.net/stripeApi`
- Endpoints:
  - `GET /health`
  - `POST /validate-email`
  - `POST /create-payment-intent`
  - `GET /payment-methods?customerKey=...`
  - `POST /customer-sheet`

## Configuracao

1. Flutter:
   - defina `STRIPE_PUBLISHABLE_KEY` (em `launch.json` ou ambiente)
   - `STRIPE_BACKEND_URL` agora e opcional
   - se nao definir `STRIPE_BACKEND_URL`, o app usa Cloud Functions por padrao
2. Firebase Functions:
   - usar projeto `ecommerce-40890`
   - configurar segredos:
     - `firebase functions:secrets:set STRIPE_SECRET_KEY --project ecommerce-40890`
     - `firebase functions:secrets:set ZEROBOUNCE_API_KEY --project ecommerce-40890`

## Deploy da API Stripe

Uma vez:

```powershell
cd functions
npm install
cd ..
```

Deploy:

```powershell
firebase deploy --only functions:stripeApi --project ecommerce-40890
```

Teste rapido:

```powershell
curl https://southamerica-east1-ecommerce-40890.cloudfunctions.net/stripeApi/health
```

Resposta esperada:

```json
{"ok":true}
```

## Rodando o app

Com Cloud Functions (recomendado):

- use o launch config `Flutter Android Cloud Functions Stripe`
- ou rode `flutter run` com `STRIPE_PUBLISHABLE_KEY`

Com backend local opcional (dev):

```powershell
powershell -ExecutionPolicy Bypass -File .\run-dev.ps1
```

No celular Android na mesma rede Wi-Fi (backend local):

```powershell
powershell -ExecutionPolicy Bypass -File .\run-dev.ps1 -UseLocalIp -d <device_id>
```

## Fluxo atual

1. No carrinho, escolha `Cartao` ou `Google Pay` em `Metodo Pagamento`
2. Em `Cartao`, marque `Salvar cartao para proximas compras` se desejar
3. Toque em `Finalizar Pedido`
4. `Cartao` abre o `PaymentSheet`; `Google Pay` abre a carteira do Google no Android suportado
5. Em `Perfil > Pagamentos`, veja os cartoes salvos e use `Adicionar cartao`

## Observacoes de seguranca

- Nunca exponha `STRIPE_SECRET_KEY` no app Flutter.
- Nunca exponha `ZEROBOUNCE_API_KEY` no app Flutter.
- Se uma chave secreta for exposta acidentalmente, revogue no Stripe e gere uma nova.
