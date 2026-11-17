# Plano — Migração `flutter_inapp_purchase` → `in_app_purchase` (oficial)

> Objetivo: trocar o SDK de compras **sem alterar regra de negócio**. O app deve
> continuar fazendo exatamente o mesmo: buscar o produto, assinar, restaurar,
> reconhecer (Android) / finalizar (iOS) e preencher `autoRenewing`,
> `purchaseToken` e `productId` no `InfoUser`.
>
> Segue `.pi/ARCHITECTURE.md` (§3 DataSource, §6 UseCase, §10 Models, Ponytail).

## ✅ Status da implementação (2026-11-17)

| Fase | Status |
|---|---|
| 0 — Baseline Android / build antigo | ⏳ **Manual (pendente)** — gerar o build antigo a partir do commit `b8c2380` antes de publicar |
| 1 — Dependência | ✅ `in_app_purchase ^3.3.1`, `in_app_purchase_android ^0.5.5` (Billing 9.1.0), `in_app_purchase_storekit ^0.4.17`; removido o workaround do `flutter_inapp_purchase` em `android/build.gradle`; `openiap` saiu dos `Package.resolved` |
| 2 — core/in_app_purchase | ✅ models `IapProduct`/`IapPurchase`, DataSource, contrato e RepositoryImpl |
| 3 — ViewModels | ✅ subscription, login, signup (mesma lógica; acesso direto ao SDK removido) |
| 4 — Testes unitários | ✅ 16 testes em `test/modules/core/in_app_purchase/` (pegaram 1 bug de tipo covariante na escolha da oferta, corrigido) |
| 4 — Testes manuais (upgrade, expiração, sandbox) | ⏳ **Pendente** — §5.4 e §0.1 |
| Build | ✅ `flutter build apk --debug` e `flutter build ios --debug --no-codesign` OK |
| 5 — Release escalonado | ⏳ Pendente |

Confirmado no código dos plugins: `purchaseStream` é broadcast nas duas
plataformas (R9 ok); `GooglePlayProductDetails.price` usa a **primeira** fase
(R6 era real → tratado); no StoreKit 2 só `purchased` tem
`pendingCompletePurchase = true` e `canceled` não tem `purchaseID` (por isso a
finalização é sempre condicionada a `pendingCompletePurchase`).

## 0. Premissas de negócio (2026-11-17)

| Plataforma | Assinantes ativos | Regra da migração |
|---|---|---|
| **Android** | **Sim** | **Mudança zero de comportamento.** Mesma fonte de dados (Billing `queryPurchasesAsync`), mesmos campos, mesma regra (mais recente de todas, sem filtrar sku), mesmo fallback `false` em erro. Qualquer diferença bloqueia o release. |
| **iOS** | Nenhum | Começa do zero com a regra correta da Apple: **premium = entitlement ativo** (decisão A, §5.2). Sem baseline do pacote antigo. |

### 0.1 Invariante de premium (vale para as duas plataformas)

| Situação | Premium? |
|---|---|
| Assinatura ativa renovando | ✅ Sim |
| Cancelou a renovação, **ainda dentro do período pago** | ✅ Pode (permitido, não obrigatório) |
| **Período pago terminou** (expirou) | ❌ **Nunca** — bloqueante |
| Reembolsada / revogada | ❌ Nunca |
| Compra pendente (pagamento não confirmado) | ❌ Não conceder premium |

- **iOS**: `currentEntitlements()` só retorna o que não expirou nem foi revogado
  → após a data de expiração some da lista → `autoRenewing = false`.
- **Android**: mantém `isAutoRenewing` (mudança zero). Hoje quem cancela já
  perde premium na hora, o que também respeita o invariante. Expirada não
  aparece no `queryPurchasesAsync` → lista vazia → `false`.
  *Opcional futuro*: igualar ao iOS (premium até expirar) usando “existe compra
  ativa com `purchaseState == PURCHASED`”. Só aumenta quem é premium dentro do
  período pago; ninguém perde. Fazer em PR separado, não nesta migração.
- **Limitação já existente (não muda) — ✅ aceita pelo negócio (2026-11-17), não
  criar listener global nem timer por causa disso**: a checagem roda no login/auto-login e
  ao sair da tela de assinatura. Se o app ficar aberto atravessando a data de
  expiração, o premium só cai na próxima abertura. Se a consulta à loja falhar,
  o `catch` grava `false` (nunca concede premium por erro).

---

## 1. Inventário — onde o pacote antigo é usado hoje

| Arquivo | Uso |
|---|---|
| `core/in_app_purchase/data/datasource/in_app_purchase_remote_datasource.dart` | Único ponto que deveria falar com o SDK |
| `core/in_app_purchase/data/repository/in_app_purchase_repository_impl.dart` | Repassa tipos do plugin |
| `core/in_app_purchase/domain/repository/in_app_purchase_repository.dart` | Contrato expõe `ProductCommon`, `Purchase`, `PurchaseError`, `RequestPurchaseBuilder` |
| `subscription/presenter/subscription_view_model.dart` | `init`, `requestSubscription`, `_onPurchaseUpdated`, `_fail`, `restorePurchases`, `checkExistingSubscription`. **Chama `FlutterInappPurchase.instance` direto (linhas 143 e 221) — viola a regra “chamada externa só no DataSource”.** |
| `auth/presenter/login/login_view_model.dart` | `init()` (initConnection + fetchProducts de aquecimento) e checagem pós-login (`getAvailablePurchases` → sessão + acknowledge) |
| `auth/presenter/singup/singup_view_model.dart` | Mesma checagem pós-cadastro/Google |
| `pubspec.yaml` | `flutter_inapp_purchase: ^11.4.0` |

**Não muda (consumidores de `autoRenewing`)**: `core/ads`, `display_alert`,
`chat_assistant`, `pdf_menu`, `pdf_edit`, `product_price_list`, `budget_list`.
Dados persistidos no Firestore (`AutoRenewing`, `ProductId`, `PurchaseToken`)
**mantêm nome e tipo** (Regra Zero).

---

## 2. Diferenças de API que importam

| Hoje (`flutter_inapp_purchase`) | Oficial (`in_app_purchase`) | Impacto |
|---|---|---|
| `initConnection()` / `endConnection()` | Não existe conexão; só `isAvailable()` | `initConnection` vira `isAvailable()` (lança se `false`). `endConnection` não é usado em lugar nenhum → **deletar**. |
| `fetchProducts<ProductSubscription>(skus)` | `queryProductDetails(Set<String>)` → `ProductDetailsResponse` (`productDetails`, `notFoundIDs`, `error`) | No Android vem **um `GooglePlayProductDetails` por base plan/oferta**, não um produto com lista de ofertas. |
| `displayPrice` | `price` (String formatada) | Verificar qual fase de preço o oficial usa quando há trial (ver R6). |
| `subscriptionOffers.first.offerTokenAndroid` | `GooglePlayProductDetails.offerToken` | O `GooglePlayPurchaseParam` já usa o offerToken do `ProductDetails` escolhido. |
| `requestPurchaseWithBuilder` | `buyNonConsumable(purchaseParam: PurchaseParam / GooglePlayPurchaseParam)` | Assinatura usa `buyNonConsumable` (sim, é o correto para subs). Retorna `bool` só de “pedido enviado”; resultado vem no stream. |
| `purchaseUpdatedListener` (`Stream<Purchase>`) + `purchaseErrorListener` (`Stream<PurchaseError>`) | **Um único** `purchaseStream` (`Stream<List<PurchaseDetails>>`) com `status`: `pending`, `purchased`, `restored`, `error`, `canceled` | Repository precisa achatar a lista e separar erro/cancelado. |
| `PurchaseState.Purchased` em restore | `PurchaseStatus.restored` | **Se não mapear, o VM cai no `else` → `SubscriptionState.error`** (ver R3). |
| `acknowledgePurchaseAndroid(token)` + `finishTransaction(purchase)` | `completePurchase(PurchaseDetails)` (acknowledge no Android, finish no iOS) quando `pendingCompletePurchase == true` | Precisa do objeto `PurchaseDetails`, não do token. |
| `getAvailablePurchases()` | **Não existe** no plugin base. Android: `InAppPurchaseAndroidPlatformAddition.queryPastPurchases()`. iOS: `SK2Transaction.currentEntitlements()` (`in_app_purchase_storekit` ≥ 0.4.16) | Maior ponto de atenção (ver R1/R2). **Não usar `restorePurchases()` no login** — no iOS pode pedir senha da Apple ID. |
| `purchase.isAutoRenewing` (unificado) | Android: `billingClientPurchase.isAutoRenewing`. iOS: **não existe** | iOS: `autoRenewing = existe entitlement ativo do sku` (ver R1). |
| `purchase.purchaseToken` | Android: `billingClientPurchase.purchaseToken`. iOS: `verificationData.serverVerificationData` (JWS no SK2) | Formato do valor salvo em `PurchaseToken` pode mudar no iOS (ver R2). |
| `transactionDate` (`int`/`double` ms) | `transactionDate` (`String?` ms) | `int.tryParse(...) ?? 0`. |
| `ErrorCode.UserCancelled` | `PurchaseStatus.canceled` | Mapear para `cancelled`. |

---

## 3. Desenho alvo (seguindo a arquitetura)

Hoje os tipos do plugin vazam até as ViewModels (`Purchase`, `PurchaseAndroid`,
`ProductSubscriptionAndroid`, `ErrorCode`). Com o oficial isso pioraria: cada VM
teria que fazer cast por plataforma para achar `isAutoRenewing`/`purchaseToken`
em 3 lugares diferentes. A conversão vai para o **RepositoryImpl** (§3.2 —
“Converter → Model é do RepositoryImpl”) com 2 models do próprio módulo (§10).

```
core/in_app_purchase/
├── in_app_purchase_binds.dart                 (sem mudança)
├── data/
│   ├── datasource/in_app_purchase_remote_datasource.dart   ← SÓ aqui importa in_app_purchase*
│   ├── model/iap_product.dart                 (novo)
│   ├── model/iap_purchase.dart                (novo)
│   └── repository/in_app_purchase_repository_impl.dart     ← converte plugin → model
└── domain/repository/in_app_purchase_repository.dart       ← contrato só com models
```

### 3.1 Models (mínimos — só o que os VMs já leem)

```dart
class IapProduct {
  final String id;
  final String displayPrice;
  final String? offerTokenAndroid; // null no iOS
}

enum IapPurchaseStatus { purchased, pending, error, cancelled }

class IapPurchase {
  final String productId;
  final String purchaseToken;
  final bool isAutoRenewing;
  final int transactionDate;
  final IapPurchaseStatus status;
  final bool needsCompletion;    // = pendingCompletePurchase
  final Object? source;          // PurchaseDetails opaco p/ completePurchase; VM nunca lê
}
```

> `isAcknowledgedAndroid` some: o VM passa a perguntar `needsCompletion`
> (no Android = `!isAcknowledged`, no iOS = transação não finalizada). Mesma
> regra, sem cast de plataforma.

### 3.2 Contrato do repository (mesmos nomes, tipos novos)

```dart
abstract class InAppPurchaseRepository {
  Future<void> initConnection();                               // isAvailable() ou throw
  Future<List<IapProduct>> fetchProducts({required List<String> skus});
  Future<void> requestSubscription(String sku);                // usa ProductDetails em cache
  Future<void> restorePurchases();
  Future<void> acknowledgePurchaseAndroid(IapPurchase p);      // → completePurchase
  Future<void> finishTransaction(IapPurchase p);               // → completePurchase
  Future<List<IapPurchase>> getAvailablePurchases();           // Android: queryPastPurchases / iOS: currentEntitlements
  Stream<IapPurchase> get purchaseUpdatedStream;               // purchased | pending (restored → purchased)
  Stream<IapPurchase> get purchaseErrorStream;                 // error | cancelled
}
```

- `endConnection` removido (sem uso).
- `requestPurchaseWithBuilder` → `requestSubscription(sku)`; o RepositoryImpl
  guarda `Map<String, ProductDetails>` do último `fetchProducts` e escolhe o
  `GooglePlayPurchaseParam` (Android) ou `PurchaseParam` (iOS).

### 3.3 DataSource (só SDK, injetável para teste — §3.3.4)

```dart
class InAppPurchaseRemoteDataSource {
  InAppPurchaseRemoteDataSource({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;
  final InAppPurchase _iap;

  Future<bool> isAvailable() => _iap.isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) => _iap.queryProductDetails(ids);
  Future<bool> buyNonConsumable(PurchaseParam p) => _iap.buyNonConsumable(purchaseParam: p);
  Future<void> restorePurchases() => _iap.restorePurchases();
  Future<void> completePurchase(PurchaseDetails p) => _iap.completePurchase(p);
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  // Android
  Future<QueryPurchaseDetailsResponse> queryPastPurchasesAndroid() => _iap
      .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
      .queryPastPurchases();

  // iOS (StoreKit 2)
  Future<List<SK2Transaction>> currentEntitlementsIos() => SK2Transaction.currentEntitlements();
}
```

### 3.4 Mudanças nos VMs (troca de tipo, **mesma lógica**)

`subscription_view_model.dart`
- `List<ProductSubscription>` → `List<IapProduct>`; `displayPrice` igual.
- `requestSubscription`: mantém a checagem do offerToken no Android
  (`product.offerTokenAndroid == null` → `throw Exception(SubscriptionStrings.offerTokenError(sku))`)
  e chama `_iap.requestSubscription(sku)`.
- `_onPurchaseUpdated(IapPurchase)`: mesma árvore de `if`:
  - `purchased` → Android `if (needsCompletion) acknowledgePurchaseAndroid(p)`;
    iOS `finishTransaction(p)`; `success`.
  - `pending` → `success` (igual hoje).
  - linhas 143 e 221: `FlutterInappPurchase.instance.acknowledgePurchaseAndroid`
    → `_iap.acknowledgePurchaseAndroid(...)` (corrige a violação da arquitetura).
- `_fail`: `e is PurchaseError && e.code == ErrorCode.UserCancelled`
  → `e is IapPurchase && e.status == IapPurchaseStatus.cancelled`.
- `checkExistingSubscription`: só troca tipos.

`login_view_model.dart` / `singup_view_model.dart`
- `fetchProducts<ProductSubscription>(skus: …)` → `fetchProducts(skus: …)`.
- Bloco `getAvailablePurchases` → só troca `latestSubscription is PurchaseAndroid
  && isAcknowledgedAndroid != true` por `latestSubscription.needsCompletion`,
  e passa o objeto em vez do token.
- Remover `import 'package:flutter_inapp_purchase/...'`.

> **Fora de escopo (de propósito)**: a lógica “pega a compra mais recente →
> preenche sessão → acknowledge” está duplicada em 3 VMs. Pela regra
> “regra de negócio = usecase” ela deveria virar um `SyncSubscriptionUsecase`,
> mas isso é refatoração de regra de negócio — fazer **depois**, em PR separado,
> com a migração já estável.

---

## 4. Passo a passo de execução

**Fase 0 — Baseline (antes de tocar no código)**
1. **Só Android** (iOS não tem assinantes — §0). Em teste interno, com o pacote
   **antigo**, anotar para cada cenário: valor de `autoRenewing`,
   `purchaseToken`, `productId`, `displayPrice` mostrado, estado final da tela.
   Cenários: sem assinatura · assinatura ativa · assinatura cancelada mas dentro
   do período pago · expirada · compra pendente (Android “cartão lento”) ·
   cancelar no sheet · restaurar sem nada · restaurar com assinatura.
2. ~~Verificar se algum backend/Cloud Function lê `PurchaseToken` do Firestore.~~
   ✅ **Feito (2026-11-17)**: só `lib/modules/auth` grava/lê o campo;
   `functions/index.js` não usa `PurchaseToken`, `AutoRenewing` nem recibo.
   R2 eliminado.
3. ~~Decidir a semântica do R1.~~ ✅ **Decidido: A** (iOS sem assinantes, §0).
4. Gerar e guardar um **build do app atual (pacote antigo)** para o teste de
   upgrade da §5.4.

**Fase 1 — Dependência**
1. `pubspec.yaml`: remover `flutter_inapp_purchase`; adicionar `in_app_purchase`,
   `in_app_purchase_android`, `in_app_purchase_storekit` (os dois últimos
   explícitos porque importamos `InAppPurchaseAndroidPlatformAddition` e
   `SK2Transaction`; `storekit >= 0.4.16` para `currentEntitlements`).
2. **Remover e adicionar no mesmo commit** — não conviver com os dois (duas
   Billing Libraries / dois observers de StoreKit, ver R8).
3. `flutter clean && flutter pub get`; iOS: limpar resolução SPM/DerivedData.

**Fase 2 — core/in_app_purchase**: models → datasource → repository impl →
contrato (seção 3).

**Fase 3 — VMs**: subscription → login → signup (seção 3.4). `flutter analyze`
sem warnings e `grep -r flutter_inapp_purchase lib` vazio.

**Fase 4 — Testes**
- Unit (novo): `InAppPurchaseRepositoryImpl` com datasource fake cobrindo o
  mapeamento: `restored→purchased`, `canceled→cancelled`, `error→errorStream`,
  `transactionDate` nulo/inválido, lista vazia, Android `isAcknowledged=true`
  → `needsCompletion=false`.
- Manual Android: repetir **todos** os cenários da Fase 0 e comparar lado a
  lado. Qualquer diferença em `autoRenewing` = parar.
- **Teste de upgrade Android (obrigatório, §5.4)**.
- Manual iOS (sandbox): assinar, restaurar, cancelar renovação (continua
  premium até expirar), expirar (perde premium), relogar sem pedir senha.
- **Teste de expiração (invariante §0.1, bloqueante)** — nas duas plataformas,
  usando a renovação acelerada (sandbox Apple e *license tester* da Play: 1 mês
  ≈ 5 min): assinar → cancelar renovação → esperar expirar → reabrir o app →
  **não pode ser premium** (anúncio aparece, PDF bloqueado). Repetir com
  reembolso/revogação. Compra pendente não pode liberar premium.

**Fase 5 — Release**
- Android: rollout escalonado na Play (10% → 50% → 100%).
- iOS: phased release da App Store.
- Monitorar Crashlytics e reclamações de “perdi o premium / vejo anúncio
  sendo assinante”. Rollback = reverter o PR (dados persistidos não mudam).

---

## 5. Riscos

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|---|
| ~~**R1**~~ | ~~**iOS `autoRenewing` diferente do atual.**~~ | — | — | ✅ **Eliminado.** iOS não tem assinantes; regra nova = entitlement ativo (decisão A, §5.2). |
| **R15** | **Assinante Android perde premium após atualizar o app** (leitura errada da assinatura existente, exceção caindo no `catch` → `autoRenewing=false`, filtro de sku que o código atual não tem). | Baixa | **Crítico** | §5.4: mesma consulta da Billing, sem filtro de sku, teste de upgrade obrigatório, rollout escalonado com pausa. |
| ~~**R2**~~ | ~~**Formato do `PurchaseToken` no iOS muda** e é salvo no Firestore.~~ | — | — | ✅ **Eliminado.** Nenhum backend lê o campo (só `lib/modules/auth` grava/lê; `functions/` não usa). O valor só faz ida e volta no Firestore. Só voltaria a importar se um dia houver validação de recibo no servidor — aí usar o JWS. |
| **R3** | **`PurchaseStatus.restored` cai no `else` → tela de erro** após restaurar. | Alta se esquecer | Médio | Mapear `restored → purchased` no RepositoryImpl + teste unitário. |
| **R4** | **Acknowledge Android perdido → Google reembolsa em 3 dias.** `completePurchase` só reconhece se `pendingCompletePurchase == true` e exige o `PurchaseDetails`. | Média | **Alto** | `needsCompletion` vem de `pendingCompletePurchase`; login/signup continuam chamando acknowledge via `queryPastPurchases`. Testar com compra de teste e conferir no Play Console que ficou “Reconhecida”. |
| **R5** | **Transação iOS não finalizada** em erro/cancelamento fica na fila e reaparece a cada abertura. O oficial recomenda `completePurchase` sempre que `pendingCompletePurchase`, inclusive em erro. | Média | Médio | No RepositoryImpl, completar automaticamente itens de erro/cancelado com `pendingCompletePurchase` antes de emitir no `purchaseErrorStream` (técnico, não muda regra). |
| **R6** | **Preço exibido diferente** quando o plano tem trial/oferta introdutória (oficial gera 1 `ProductDetails` por oferta; `.price` pode ser da fase de trial, ex. “Grátis”). Também muda **qual oferta** é comprada se a ordem diferir. | Média | Médio (conversão/review) | **Contornável 100% no RepositoryImpl** (ver §5.3). Escolher a mesma oferta do antigo e exibir o preço da fase recorrente, não do trial. Conferir contra o baseline do `displayPrice`. |
| **R7** | **Listener só existe na tela de assinatura.** Compra pendente que conclui fora dessa tela (Ask to Buy, boleto/cartão lento) não é processada na hora. | Já existe hoje | Médio | Comportamento igual ao atual: o acknowledge acontece no próximo login/auto-login. Não mudar agora; anotar como melhoria futura (listener global no `core`). |
| **R8** | **Conflito de build** se os dois pacotes coexistirem (Billing Library 9.1 do oficial vs a do openiap; duas classes observando `SKPaymentQueue`/`Transaction.updates`). | Alta se coexistir | Alto (build quebra ou compras duplicadas) | Remover e adicionar no mesmo commit; `flutter clean`. |
| **R9** | **`purchaseStream` ouvido duas vezes** (updated + error derivados). Se não for broadcast → `Bad state: Stream has already been listened to`. | Baixa | Médio | Derivar os dois de um único `asBroadcastStream()`/`StreamController` no RepositoryImpl, ou confirmar que o stream do plugin é broadcast. |
| **R10** | **`getAvailablePurchases` no iOS sem `restorePurchases`**: se alguém “simplificar” usando `restorePurchases()` no login, o iOS pode pedir senha da Apple ID a cada login. | Média | Alto (UX + rejeição) | Usar só `SK2Transaction.currentEntitlements()`. Deployment target já é iOS 15 (SK2 disponível). |
| **R11** | **Restaurar sem nada** no iOS emite lista vazia → tela fica em `loading` para sempre. | Média | Baixo | Conferir no baseline o que o antigo faz. Se o antigo voltava a `idle`, replicar; se não, manter igual e anotar. |
| **R12** | **Versões**: `in_app_purchase` 3.3.x exige Flutter ≥ 3.38 / Dart 3.10 (projeto: 3.50 ✓); Android minSdk 23 (projeto: 24 ✓); iOS mínimo 13 (projeto: 15 ✓). | Baixa | Baixo | Só confirmar no `pub get`. |
| **R13** | **Produto não encontrado** (`notFoundIDs` / `error` na resposta) não lança exceção no oficial; o antigo podia lançar. | Média | Baixo | RepositoryImpl retorna lista vazia (o VM já trata `hasProducts == false`); logar em debug. |
| **R14** | **Sandbox ≠ produção**: renovação acelerada no sandbox, contas de teste da Play. | — | — | Testar renovação e expiração no sandbox antes do rollout. |

### 5.1 Status dos riscos principais

| Risco | Contorno | Tipo | Risco residual |
|---|---|---|---|
| R1 `autoRenewing` iOS | `currentEntitlements()`, decisão A | ✅ Eliminado | Nenhum (sem assinantes iOS) |
| R15 assinante Android perde premium | §5.4 | Código + teste de upgrade | Baixo — coberto pelo rollout escalonado |
| R2 `PurchaseToken` | — | ✅ Eliminado | Nenhum |
| R3 `restored` vira erro | `restored → purchased` no RepositoryImpl + teste | Código | Nenhum |
| R4 acknowledge Android | `IapPurchase.source` guarda o `PurchaseDetails`; `queryPastPurchases` devolve o objeto pronto p/ `completePurchase`; login já reconhece de novo a cada entrada | Código | Baixo — conferir “Reconhecida” no Play Console |
| R6 preço “Grátis” | Seleção de oferta + fase recorrente (§5.3) | Código | Nenhum após comparar com baseline |
| R8 dois pacotes | Remover/adicionar no mesmo commit + `flutter clean` | Procedimento | Nenhum |
| R10 senha Apple ID no login | `currentEntitlements()`; nunca `restorePurchases()` no login (iOS 15 ✓) | Código | Nenhum |

### 5.2 ✅ Decidido — semântica do `autoRenewing` no iOS: **A** (2026-11-17)

> Como não há assinantes iOS (§0), não há comportamento atual a preservar.
> Implementar **A**. O texto abaixo fica como registro da análise.

Hoje `autoRenewing` funciona como “é premium” (ads, PDF, chat, lista de
preços). Cenário: usuário cancela a renovação no iOS mas ainda está no período
pago.

- **A — ativa = premium** *(recomendado)*: mantém premium até expirar. É o que a
  Apple espera e o que `currentEntitlements()` entrega naturalmente.
  Implementação: `autoRenewing = entitlements.any((t) => t.productId == sku)`.
- **B — replicar o pacote antigo**: se o antigo retorna `false` nesse caso, o
  usuário perde o premium no momento em que cancela, mesmo tendo pago o mês.
  Implementação: além do entitlement, ler o `willAutoRenew` do renewal info do
  StoreKit 2 (confirmar se o `in_app_purchase_storekit` expõe; senão, exige
  um método nativo pequeno — evitar).

**Como decidir**: teste na sandbox com o pacote antigo (Fase 0, passo 3). Se o
antigo já se comporta como A, não há mudança e o R1 desaparece. Se se comporta
como B, decidir conscientemente: A é mudança de regra de negócio (a favor do
usuário) e precisa ser aprovada; B mantém o comportamento atual.

> Android não tem essa questão: `billingClientPurchase.isAutoRenewing` é o mesmo
> dado da Billing Library que o pacote antigo já lia.

### 5.3 Contorno do preço exibido (R6)

No Android, `queryProductDetails` devolve **um `GooglePlayProductDetails` por
oferta/base plan** do sku. No RepositoryImpl:

1. Filtrar os `GooglePlayProductDetails` com `id == sku`.
2. Escolher o de `subscriptionIndex == 0` — corresponde a
   `subscriptionOfferDetails.first`, a mesma oferta que o pacote antigo usava
   (`subscriptionOffers.first`). Guardar esse objeto no cache usado pelo
   `requestSubscription` → mesma oferta comprada que hoje.
3. `displayPrice` = `formattedPrice` da **última** `pricingPhase` dessa oferta
   (fase recorrente), não da primeira (que pode ser trial/introdutória).
4. `offerTokenAndroid` = `offerToken` desse mesmo objeto.

No iOS, `ProductDetails.price` já é o preço regular (oferta introdutória vem
separada), então só se usa `price`.

Validação: comparar o texto do preço na tela com o baseline da Fase 0. Se o
antigo mostrava o preço do trial, replicar a fase que ele usava.

### 5.4 Proteção dos assinantes Android (R15)

**Por que a assinatura existente não “some”**: a compra pertence à conta Google
+ pacote do app na Play, não ao plugin. O pacote antigo e o oficial consultam a
mesma API (`BillingClient.queryPurchasesAsync(SUBS)`) e recebem o mesmo objeto
`Purchase` da Billing → `isAutoRenewing`, `purchaseToken`, `products` e
`isAcknowledged` são **os mesmos dados**. Assinaturas existentes já estão
reconhecidas → `needsCompletion = false` → nenhuma chamada nova.

**O que pode quebrar (só por erro nosso) e a regra para evitar:**

| Ponto | Regra de implementação |
|---|---|
| Consulta | `getAvailablePurchases()` no Android = **apenas** `queryPastPurchases()`. Nunca `restorePurchases()` + stream. |
| Erro na consulta | `QueryPurchaseDetailsResponse.error != null` → **lançar exceção** (cai no `catch` atual → `false`, igual hoje). Não retornar lista vazia silenciosa sem log. |
| Filtro | **Não filtrar por sku** no Android. O código atual pega a mais recente de **todas** as assinaturas ativas (cobre quem assinou um sku/base plan antigo). |
| Mais recente | `transactionDate` = `billingClientPurchase.purchaseTime` (int ms), mesmo critério do `reduce` atual. |
| `isAutoRenewing` | `billingClientPurchase.isAutoRenewing` — nada derivado. Mesma regra de hoje (cancelou renovação → `false`), **não alterar** no Android. |
| `purchaseToken` / `productId` | `billingClientPurchase.purchaseToken` / `productID` — mesmo valor salvo hoje no Firestore. |
| Acknowledge | Só quando `pendingCompletePurchase == true` (= `!isAcknowledged`). |

**Teste de upgrade (obrigatório antes do release):**
1. Instalar o build **antigo** (Fase 0, passo 4) com uma conta *license tester*.
2. Assinar → confirmar premium (sem anúncio, PDF liberado).
3. Instalar o build **novo por cima** (sem desinstalar).
4. Abrir o app (auto-login) → premium **continua**, `PurchaseToken` e
   `ProductId` no Firestore **iguais** ao passo 2.
5. Logout → login → premium continua.
6. Sem internet → comportamento igual ao build antigo.
7. Repetir com uma conta que assinou e **cancelou a renovação** → mesmo
   resultado do build antigo.

**Release Android**: rollout escalonado na Play começando em **5–10%**, com
pausa imediata se aparecer relato de “sou assinante e vejo anúncio”. Rollback =
pausar rollout + reverter PR (nenhum dado persistido muda de formato).

---

## 6. Checklist final

- [x] Decisão A/B do R1 registrada (§5.2) — A
- [ ] Teste de upgrade Android (§5.4) passou: assinante continua premium após atualizar
- [ ] Teste de expiração (§0.1) passou nas duas plataformas: expirada/reembolsada nunca é premium
- [x] `grep -rn flutter_inapp_purchase lib pubspec.yaml` vazio
- [x] Nenhum VM importa `package:in_app_purchase*` (só o DataSource)
- [x] `restored → purchased` e `canceled → cancelled` com teste unitário
- [ ] Todos os cenários da Fase 0 iguais ao baseline (principalmente `autoRenewing`)
- [ ] Compra Android aparece “Reconhecida” no Play Console
- [ ] Transação iOS finalizada (não reaparece ao reabrir o app)
- [x] Campos `AutoRenewing`, `ProductId`, `PurchaseToken` no Firestore com o mesmo nome/tipo
- [ ] Rollout escalonado configurado nas duas lojas
