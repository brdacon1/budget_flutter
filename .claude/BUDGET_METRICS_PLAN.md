# Plano — Tela de Métricas do Orçamento

> Segue `.pi/ARCHITECTURE.md` (MVVM + Clean simplificada, ponytail).
> Objetivo: uma tela, acessada pelo **Mais** (1ª posição), que reúne todas as
> métricas de **um** orçamento, gastando o mínimo de dados móveis e de leituras
> do Firestore.

---

## 1. Métricas e de onde cada uma vem

| # | Métrica | Fonte | Custo Firestore |
|---|---------|-------|-----------------|
| 1 | Total do orçamento | `CustomerInfo.totalValue` (já em memória, vem por argumento) | **0** |
| 2 | Total de itens (qtde) | `ITENS` → `count()` | ~1 leitura |
| 3 | Total em serviços | `ITENS` → `where CATEGORIA in [valores de serviço]` → `sum('TOTAL')` | ~1 leitura |
| 4–7 | Recibos em Dinheiro / PIX / Crédito / Débito | `PAGAMENTOS` do orçamento, agrupado por `METODO` | 1 leitura por pagamento |
| 8 | Total de recibos | soma dos 4 acima (pagamentos registrados) + qtde de recibos via `RECIBOS.count()` | ~1 leitura |
| 9 | Total de comprovantes | `COMPROVANTES.count()` (já existe `countProofs`) | ~1 leitura |
| 10 | Valor a receber | `totalOrçamento − totalRecibos` (cálculo puro, nunca < 0) | **0** |

**Total típico: ~4 leituras + nº de pagamentos**, em vez de baixar todos os
itens, recibos e pagamentos.

> Decisão: "total de recibos" = soma dos **pagamentos registrados**
> (`PAGAMENTOS.PRECO`), para fechar com a quebra por método e com o "valor a
> receber". A quantidade de recibos aparece como subtítulo.

---

## 2. Estratégia para economizar dados

1. **Aggregation queries** (`count()`, `sum()`) — o servidor devolve só o
   número; cobra 1 leitura a cada 1000 entradas de índice e trafega bytes.
   Usadas em itens, serviços, recibos e comprovantes.
2. **Pagamentos do orçamento em 1 query**: `collectionGroup('PAGAMENTOS')`
   limitado ao prefixo `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{budgetId}/`
   (mesmo padrão de `getAllUserPayments`, mas escopo do orçamento). Usa o índice
   de collection group já publicado para o ledger.
   - **Fallback** (se o collectionGroup for recusado): `getReceipts` +
     `getPayments` por recibo — mesmo padrão de `_loadPerBudget`.
   - Não usar `ReceiptLedgerRepository.fetchLedger`: baixa **todos** os recibos
     do usuário.
3. **Paralelo**: as 5 consultas em `Future.wait` (1 ida à rede).
4. **Sem listener** (`snapshots()`): só `get()`. Recarrega apenas no
   pull-to-refresh.
5. **Total do orçamento** vem do `CustomerInfo` recebido — nada de reler o doc.

### Risco a validar antes de implementar
- `sum('TOTAL')` ignora valores que não sejam número. O model grava `double`,
  mas o `_convertToDouble` aceita `String` (legado). Conferir no console se há
  itens com `TOTAL` string. Se houver, trocar a métrica 3 por `get()` de
  `ITENS` (custo = nº de itens) — o `count()` continua.

---

## 3. i18n — Regra Zero (bug existente a corrigir junto)

`PaymentStrings.paymentTypeOptions` **grava o texto traduzido** em `METODO`
(`Crédito`/`Credit`, `Dinheiro`/`Cash`…). Isso viola a Regra Zero e quebraria o
agrupamento por método.

- Criar `enum PaymentMethod { credit('Crédito'), debit('Débito'), cash('Dinheiro'), pix('PIX') }`
  em `lib/modules/receipt/domain/entity/payment_method.dart`, no mesmo molde de
  `ItemCategory`: `value` fixo (gravado), `label` traduzido, `fromValue` aceitando
  legados (`credit`, `credito`, `cash`, `debit`, `debito`, `pix`, case-insensitive).
- O seletor de pagamento passa a gravar `PaymentMethod.value`; a tela só exibe
  `label`. Nenhum dado existente é migrado.
- Valor desconhecido → somado em "Outros" (não some do total).

Serviços: usar `ItemCategory.services` e a lista de variantes legadas de
`ItemCategory.fromValue` no `whereIn` (`Serviços`, `Servicos`, `Serviço`,
`Servico`, `Services`, `Service`).

---

## 4. Arquivos

### Data (budget)
```
lib/modules/budget/data/datasource/budget_metrics_remote_datasource.dart
lib/modules/budget/data/repository/budget_metrics_repository_impl.dart
```
`BudgetMetricsRemoteDatasource` (só `Map`/primitivos — §3 da arquitetura):
- `Future<({int count, double services})> itemsAggregate(uid, budgetId, List<String> serviceValues)`
- `Future<int> receiptsCount(uid, budgetId)`
- `Future<int> proofsCount(uid, budgetId)`
- `Future<List<Map<String, dynamic>>> budgetPayments(uid, budgetId)` (collectionGroup + fallback)

> Comprovantes/recibos ficam no datasource do budget (apenas leitura agregada do
> caminho do orçamento) para não acoplar o budget aos repositórios de
> `receipt`/`payment_proof`.

### Domain (budget)
```
lib/modules/budget/domain/entity/budget_metrics.dart
lib/modules/budget/domain/repository/budget_metrics_repository.dart
lib/modules/budget/domain/usecase/get_budget_metrics_usecase.dart
```
- `BudgetMetrics` (imutável): `budgetTotal`, `servicesTotal`, `itemsCount`,
  `byMethod: Map<PaymentMethod?, double>`, `receiptsTotal`, `receiptsCount`,
  `proofsCount`, getter `toReceive = max(0, budgetTotal − receiptsTotal)`.
- `GetBudgetMetricsUsecase(CustomerInfo)` → `Result<BudgetMetrics>`: dispara o
  repositório, agrupa pagamentos por `PaymentMethod.fromValue` (regra de
  negócio = usecase).

### Presenter (tela própria — modal complexo é tela)
```
lib/modules/budget/presenter/budget_metrics/
├── budget_metrics_view.dart
├── budget_metrics_view_model.dart
└── components/
    ├── budget_metrics_hero_card.dart        # total do orçamento + a receber + barra de progresso
    ├── budget_metrics_tile.dart             # card pequeno (ícone, título, valor) — grid 2 col
    ├── budget_metrics_methods_card.dart     # barra segmentada + linhas por método (estilo "Order Status")
    └── budget_metrics_skeleton.dart         # loading
```
Strings em `lib/modules/budget/presenter/strings/budget_pt_string.dart`.

### Layout (referência das imagens)
1. **Hero**: Total do orçamento (grande) · "A receber" · anel/barra `% recebido`.
2. **Grid 2×2**: Itens · Serviços · Recibos (qtde) · Comprovantes.
3. **Card "Recebimentos"**: total de recibos + barra segmentada colorida +
   linhas Dinheiro / PIX / Crédito / Débito com valor e `%`.
4. `RefreshIndicator` para recarregar.

### Binds / rotas / menu
- `budget_binds.dart`: registrar datasource, repo, usecase e
  `BudgetMetricsViewModel` (factory).
- `budget_routes.dart`: `BudgetRoute.metrics` → `/budget/metrics` (navegação via
  `MaterialPageRoute` com `CustomerInfo`, igual às outras telas com argumento).
- **Mais** (`lib/modules/pdf/presenter/pdf_menu/pdf_menu_view_model.dart`):
  inserir `MenuItem(icon: Icons.insights_outlined, title: PdfStrings.menuMetrics)`
  na **posição 0**.
  - Hoje `openOption` usa `switch (index)` com índices fixos — inserir na
    frente desloca todos. Trocar para um `enum PdfMenuOption` no `MenuItem` e
    `switch (option)`, para não quebrar as ações existentes (inclusive o item
    condicional de IA).

---

## 5. Ordem de implementação

1. `PaymentMethod` enum + seletor gravando `value` (corrige Regra Zero).
2. Datasource + teste manual das 4 consultas (validar `TOTAL` numérico e índice).
3. Entity, repositório, usecase (+ teste unitário do agrupamento e do `toReceive`).
4. ViewModel + View + components.
5. Binds, rota e item na 1ª posição do **Mais** (com enum de opção).
6. `flutter analyze` e teste no app: orçamento sem recibos, com recibo parcial,
   quitado, com método legado em inglês.

## 6. Fora de escopo
- Cache persistente/offline das métricas.
- Métricas agregadas de vários orçamentos (já existem no dashboard/relatório).
