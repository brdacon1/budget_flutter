# Premium — Assinaturas mensal e anual (guia de loja e acesso à tela)

> Documento para cadastrar os produtos na **App Store Connect** e no **Google Play
> Console** e para o **App Review** da Apple. Textos de loja e notas de revisão
> estão em **inglês**, prontos para copiar.
>
> Implementação: módulo `subscription` + `core/in_app_purchase`
> (`SubscriptionView` / `SubscriptionViewModel`). SKUs vêm de `env/*.json`
> (`Environment.instance.subscription`), nunca hardcoded.

---

## 1. Chaves dos produtos (`env/development_environment.json` e `production_environment.json`)

| Chave do JSON | Plataforma | Plano | Product ID |
|---|---|---|---|
| `IOS_SUBSCRIPTION_SKU` | App Store | Mensal | `newproductsubscription` |
| `IOS_SUBSCRIPTION_BY_YEAR_SKU` | App Store | Anual | `premiumversionbyyear` |
| `ANDROID_SUBSCRIPTION_SKU` | Google Play | Mensal | `newproduct` |
| `ANDROID_SUBSCRIPTION_BY_YEAR_SKU` | Google Play | Anual | `premiumversionbyyear` |

```json
"IOS_SUBSCRIPTION_SKU": "newproductsubscription",
"IOS_SUBSCRIPTION_BY_YEAR_SKU": "premiumversionbyyear",
"ANDROID_SUBSCRIPTION_SKU": "newproduct",
"ANDROID_SUBSCRIPTION_BY_YEAR_SKU": "premiumversionbyyear"
```

- As quatro chaves são **obrigatórias**: `Environment.initialize()` lança erro
  explícito se alguma faltar (falhar cedo, nunca servir SKU errado).
- Bundle / package: `com.housestudio.oflite` (iOS e Android).
- O **preço não está no app**: vem sempre da loja (`displayPrice`). O app não
  mostra desconto fixo ("economize X%") para não divergir do preço cadastrado.

### 1.1 Comportamento da tela com os dois planos

| Situação | O que a tela faz |
|---|---|
| Loja devolve mensal e anual | Mostra os dois; **anual vem pré-selecionado** com selo "Melhor valor" |
| Loja só devolve o mensal | Só o mensal aparece e vem selecionado (comportamento antigo) |
| Loja só devolve o anual | Só o anual aparece |
| Loja não devolve nenhum | Mensagem de planos indisponíveis; botão desabilitado |
| Android | O `offerToken` é exigido do plano escolhido (base plan precisa existir na Play Console) |
| iOS | Botão "Restaurar compras" visível; transação é finalizada após a compra |

Regra de premium **não muda** (ver `IN_APP_PURCHASE_MIGRATION_PLAN.md` §0.1):
qualquer assinatura vigente (mensal ou anual) concede premium; expirada,
reembolsada ou pendente não concede. Dados persistidos (`AutoRenewing`,
`ProductId`, `PurchaseToken`) mantêm nome e tipo.

---

## 2. Como acessar a tela Premium no app

A tela é a `SubscriptionView` (rota `/pg-subscription`). Caminhos para chegar nela:

| # | Caminho (inglês) | Observação |
|---|---|---|
| 1 | Main config menu → **Go Premium (subscription)** | Lista que também tem *Edit PDF*, *Change username*, *Delete account* |
| 2 | Dashboard → menu do cabeçalho (nome do usuário) → **Go Premium** | Atalho no topo do dashboard |
| 3 | Budget list → **New budget** acima do limite grátis | Gate de orçamentos (`NewBudgetGate`) |
| 4 | Budget → opções do orçamento → **Go premium** | Tela `budget_options` |
| 5 | Chat assistant → recurso de IA (usuário gratuito) | Abre a assinatura em vez do modo IA |
| 6 | Comment library (Config menu → Comments) | Aviso "Premium feature" e depois a assinatura |
| 7 | PDF edit (inserir logo) e Price list acima do limite | Gates de recurso premium |

Dentro da tela: rolar para ver recursos, **escolher Monthly/Yearly**, tocar em
**SUBSCRIBE NOW** (botão fixo no rodapé). Abaixo do botão: resumo do plano,
**Restore Purchases** (iOS) e link **Terms of Use and Privacy Policy**.

---

## 3. App Store Connect (iOS)

**Subscription Group** (ex.: `Premium`)

| Campo | Valor |
|---|---|
| Group reference name | `Premium` |
| Group display name (en) | `Premium` |
| App name shown in group | `OFLite` |

### 3.1 Produto mensal — `newproductsubscription`

| Campo | Valor |
|---|---|
| Reference name | `Premium Monthly` |
| Duration | 1 Month |
| Display name (máx. 30) | `Premium Monthly` |
| Description (máx. 45) | `Unlimited budgets, AI assistant, no ads` |

### 3.2 Produto anual — `premiumversionbyyear`

| Campo | Valor |
|---|---|
| Reference name | `Premium Yearly` |
| Duration | 1 Year |
| Display name (máx. 30) | `Premium Yearly` |
| Description (máx. 45) | `All Premium features, best yearly value` |

- Colocar os dois no **mesmo grupo**, com o anual em nível de ordem acima do
  mensal (upgrade/downgrade/crossgrade corretos).
- Definir **preços** em cada território e subir o **screenshot de revisão** da
  tela Premium (a nova tela, com os dois planos).
- Localização **Portuguese (Brazil)** (opcional):
  - Mensal: nome `Premium Mensal` · descrição `Orçamentos ilimitados, IA e sem anúncios`
  - Anual: nome `Premium Anual` · descrição `Todos os recursos Premium, melhor preço`
- Na ficha do app: **Privacy Policy URL** e **EULA/Terms of Use** (link no
  campo Description do app ou EULA customizado). Páginas web do projeto:
  `/privacy-policy`, `/terms-of-use` (pt: `/politica-de-privacidade`,
  `/termos-de-uso`) em `https://orcamentofacil-lite.web.app`.

### 3.3 App Review Information — Notes (copiar)

```text
Premium subscriptions (auto-renewable)

The app offers two auto-renewable subscriptions in one subscription group:
- Premium Monthly (product ID: newproductsubscription)
- Premium Yearly  (product ID: premiumversionbyyear)

How to reach the subscription screen:
1. Sign in (or create an account) and open the app.
2. Open the main config menu and tap "Go Premium (subscription)".
   Alternative: on the Dashboard, tap the user name menu at the top and
   choose "Go Premium".
3. On the Premium screen, select "Monthly" or "Yearly" and tap
   "SUBSCRIBE NOW" (fixed button at the bottom). Prices are loaded from the
   App Store.
4. "Restore Purchases" and a link to "Terms of Use and Privacy Policy" are
   shown below the subscribe button.

What Premium unlocks:
- AI chat assistant that creates a full budget from a conversation
- Payment proofs sent through the chat (photo or shared file)
- Receipts report by week or month, in the chat
- Comment library with "Improve with AI"
- Unlimited budgets and price list, company logo on PDFs, no ads

The subscription renews automatically until cancelled in the Apple ID
account settings. Free users keep full access to the core budgeting features.
```

---

## 4. Google Play Console (Android)

Em **Monetize → Products → Subscriptions**:

### 4.1 Assinatura mensal — Product ID `newproduct`

| Campo | Valor |
|---|---|
| Name | `Premium Monthly` |
| Benefits (máx. 4, 40 caracteres cada) | `Unlimited budgets and price list` · `AI assistant creates budgets in chat` · `Company logo on your PDFs` · `No ads` |
| Base plan | 1 base plan **auto-renewing**, período **Monthly** (ex.: id `monthly`) |
| Preço | Definir por país |

### 4.2 Assinatura anual — Product ID `premiumversionbyyear`

| Campo | Valor |
|---|---|
| Name | `Premium Yearly` |
| Benefits (máx. 4, 40 caracteres cada) | `All Premium features included` · `AI assistant, receipts report, comments` · `Unlimited budgets, logo, no ads` · `Best value: pay once a year` |
| Base plan | 1 base plan **auto-renewing**, período **Yearly** (ex.: id `yearly`) |
| Preço | Definir por país |

- **Ativar** os dois base plans (o app compra o `offerToken` do primeiro base
  plan do produto — mantenha **um base plan ativo por assinatura**).
- O app Android já tem assinantes do mensal (`newproduct`): **não alterar** o
  produto nem o base plan existente.
- Licença de testadores: adicionar contas em **License testing** e testar em
  faixa de **Internal testing**.

---

## 5. Descrição em inglês (resumo para ficha/screenshot)

> **Go Premium and quote faster, with AI.**
> Chat with the smart assistant and get a complete budget built for you. Send
> payment proofs by photo, see your receipts by week or month, and save ready
> comments you can polish with AI. Premium also gives you unlimited budgets and
> price list, your company logo on every PDF, and no ads.
>
> Choose Monthly or Yearly. Payment is charged to your store account at
> confirmation of purchase. The subscription renews automatically unless it is
> cancelled at least 24 hours before the end of the current period. Manage or
> cancel anytime in your store account settings.

---

## 6. Checklist antes de enviar

- [ ] Produtos `newproductsubscription` e `premiumversionbyyear` criados e **Ready to Submit** na App Store Connect
- [ ] Produtos `newproduct` e `premiumversionbyyear` **ativos** na Play Console, com base plan
- [ ] Preços e localizações preenchidos nos dois planos
- [ ] Screenshot de revisão da tela Premium (dois planos visíveis) anexado ao produto
- [ ] Termos de uso e Política de privacidade acessíveis (link na tela + URL na ficha)
- [ ] Notas de revisão (§3.3) coladas em **App Review Information**
- [ ] Teste em sandbox (iOS) e Internal testing (Android): comprar mensal, comprar anual, restaurar (iOS), cancelar, expirar → perde premium
- [ ] Android: assinante antigo do mensal continua premium após atualizar o app
- [ ] `env/production_environment.json` com as quatro chaves de assinatura
