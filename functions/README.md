# Cloud Functions — notificação de aprovação/reprovação de orçamento

## O que isto faz

Quando o cliente aprova/reprova um orçamento pela tela Web, o fluxo Web grava
um documento em:

```
EMPRESAS/{ownerUid}/USERS/{ownerUid}/NOTIFICACOES/{notifId}
```

A função `onBudgetApprovalNotification` (em `index.js`) dispara nesse evento,
lê o token FCM do dono em:

```
EMPRESAS/{ownerUid}/USERS/{ownerUid}/FCM/TOKEN
```

e envia uma mensagem FCM com `notification` + `data`. Assim o Android exibe a
notificação na bandeja do sistema **mesmo com o app fechado**, e ao tocar o
dono é levado ao orçamento (deep-link via `data.ORCAMENTO_ID`).

## Por que é necessário

Um listener do Firestore (`.snapshots().listen`) só roda com o app **aberto**.
Para notificar com o app fechado/minimizado é preciso um **push FCM real**,
que só pode ser enviado por um servidor — daí a Cloud Function.

## Pré-requisitos

1. **Plano Blaze** (pay-as-you-go) no Firebase — Cloud Functions gen2 exige.
   (Console → Firebase → Upgrade.) O plano tem franquia generosa e o uso de
   notificações é baratíssimo.
2. **Região do Firestore**: o trigger precisa estar na mesma região do seu
   banco Firestore. Ajuste a constante `REGION` em `index.js` se necessário:
   - `southamerica-east1` (já configurado — padrão para projetos brasileiros)
   - `us-central1` (padrão de projetos antigos/defaults)

## Deploy

Na raiz do projeto:

```bash
firebase deploy --only functions
```

(O `firebase deploy` instala as dependências (`npm install`) automaticamente.)

## Local (opcional)

```bash
cd functions
npm install
npx firebase functions:shell   # emulador interativo
# ou
firebase emulators:start --only functions
```
