# Plano de Remoção: `global_uid_budget.dart` → `selectBudget` no `BudgetRepository`

> **Arquitetura**: MVVM + Clean Architecture (simplificada)  
> **Estado**: `ChangeNotifier` (repositório) + `ValueNotifier` (seleção ativa)  
> **Padrão**: ponytail — menor código completo que resolve o problema.  
> **Meta**: Eliminar variáveis globais de estado de orçamento e centralizá-las no `BudgetRepository`, única fonte de verdade.

---

## 1. Contexto e Diagnóstico

### 1.1 O problema

O arquivo `lib/shared/common/constants/global_uid_budget.dart` expõe 19 variáveis globais mutáveis (`IDORCAMENTO`, `IDRECIBO`, `VALORTOTAL`, `fromListItem`, `googleAuth`, etc.) que são lidas e escritas por **16 arquivos** espalhados em 9 módulos diferentes (`budget`, `payment`, `pdf`, `product`, `receipt`, `chat_assistant`, `core/notification`).

Isso quebra os princípios da arquitetura do projeto:

| Problema | Consequência |
|----------|--------------|
| Estado espalhado | Nenhum controle de ciclo de vida; “sair do orçamento” não garante limpeza. |
| Módulos `payment`, `receipt`, `product` acessam globais de `budget` | Acoplamento indevido; quebra camada domain. |
| `googleAuth` e `NOMEEMPRESA` estão no arquivo “budget” mas não são de orçamento | Responsabilidade errada. |
| `fromListItem` é um booleano de UI escondido numa global | Deveria ser estado local da View ou ViewModel. |

### 1.2 Campos mapeados

| Campo na global | Campo equivalente em `CustomerInfo` | Onde é usado |
|-----------------|-------------------------------------|--------------|
| `IDORCAMENTO` | `id` | budget_creator, budget_list, budget_list_items, payment, pdf, product, receipt, notification, chat_assistant |
| `VALORTOTAL` | `totalValue` | budget_creator, budget_list_items, chat_assistant |
| `IDRECIBO` | — (pertence ao módulo `receipt`) | payment, receipt, pdf_receipt |
| `ID` | `id` | budget_creator |
| `DATA` | `data` | budget_creator |
| `RUA` | `street` | budget_creator |
| `GERADO` | `generated` | budget_creator |
| `BAIRRO` | `neighborhood` | budget_creator |
| `CITY` | `city` | budget_creator |
| `CEP` | `zip` | budget_creator |
| `EMAIL` | `email` | budget_creator |
| `ENDERECO` | `address` | budget_creator |
| `FONE` | `phone` | budget_creator |
| `NOMECLIENTE` | `customerName` | budget_creator |
| `STATUS` | `status` | budget_creator |
| `fromListItem` | — (flag de UI) | budget_list_items, product_price_creator |
| `googleAuth` | — (pertence ao usuário logado) | pdf usecases (mas na prática lê `global_uid_user.dart`) |
| `NOMEEMPRESA` | — (não utilizado em nenhum lugar) | — |

### 1.3 Arquivos que **escrevem** na global

```
lib/modules/budget/data/repository/budget_repository_impl.dart
lib/modules/budget/budget_creator/presenter/budget_creator_view_model.dart
lib/modules/budget/budget_list/presenter/budget_list_view.dart
lib/modules/budget/budget_list/presenter/budget_list_view_model.dart
lib/modules/budget/budget_list_items/presenter/budget_list_items_view.dart
lib/modules/budget/budget_list_items/presenter/budget_list_items_view_model.dart
lib/modules/chat_assistant/data/repository/chat_budget_repository_impl.dart
lib/modules/core/notification/data/repository/notification_repository_impl.dart
lib/modules/payment/payment_list/presenter/payment_list_view_model.dart
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart
lib/modules/receipt/receipt_list/presenter/receipt_list_view_model.dart
lib/modules/product/product_price_list/presenter/product_price_list_view_model.dart
lib/modules/product/product_price_creator/presenter/product_price_creator_view_model.dart
```

### 1.4 Arquivos que **lêem** da global (sem escrever)

```
lib/modules/payment/data/datasource/payment_remote_datasource.dart
lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart
lib/modules/pdf/domain/usecase/pdf_generate_professional_usecase.dart
lib/modules/pdf/domain/usecase/pdf_generate_budget_usecase.dart
lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart
lib/modules/pdf/domain/usecase/pdf_generate_executive_usecase.dart
lib/modules/receipt/data/datasource/receipt_remote_datasource.dart
```

---

## 2. Decisões de Arquitetura

### 2.1 O que fica no `BudgetRepository`

O repositório já é `ChangeNotifier` e singleton (`registerLazySingleton`). Será adicionado um `ValueNotifier<CustomerInfo?> selectBudget`, seguindo exatamente o padrão solicitado:

```dart
final ValueNotifier<CustomerInfo?> _selectBudget = ValueNotifier<CustomerInfo?>(null);

@override
ValueNotifier<CustomerInfo?> get selectBudget => _selectBudget;

@override
set selectBudget(ValueNotifier<CustomerInfo?> value) {
  _selectBudget.value = value.value;
}
```

**Regra de ouro**: `selectBudget.value` substitui **todos** os campos de `CustomerInfo` que antes viviam na global (`ID`, `DATA`, `RUA`, `GERADO`, `BAIRRO`, `CITY`, `CEP`, `EMAIL`, `ENDERECO`, `FONE`, `NOMECLIENTE`, `STATUS`, `IDORCAMENTO`, `VALORTOTAL`).

> **Por que `ValueNotifier` e não apenas `selectedBudget` (`ChangeNotifier`)?**  
> O `ValueNotifier` permite reação granular via `ValueListenableBuilder` sem rebuildar toda a árvore que escuta o `BudgetRepository`. Também permite passar a referência direta para widgets/modais que precisam apenas do orçamento ativo, sem carregar o repositório inteiro.

### 2.2 O que NÃO fica no `BudgetRepository`

| Campo | Destino | Motivo |
|-------|---------|--------|
| `IDRECIBO` | `ReceiptRepository` (ou estado local da ViewModel de receipt) | Pertence ao domínio de recibo, não orçamento. |
| `googleAuth` | `global_uid_user.dart` (já existe lá) | Pertence ao usuário logado. |
| `NOMEEMPRESA` | `global_uid_user.dart` ou `CompanyInfo` | Pertence à empresa/usuário. |
| `fromListItem` | Estado local da ViewModel que precisa dele | É uma flag de navegação/transição de tela, não de domínio. |

### 2.3 Ciclo de vida do `selectBudget`

| Ação | Quem faz | Efeito |
|------|----------|--------|
| **Clicar** num orçamento na lista | `BudgetListViewModel` | `budgetRepo.selectBudget.value = customerInfo;` |
| **Entrar** no criador/editor | `BudgetCreatorViewModel` | `budgetRepo.selectBudget.value = customerInfo;` (ou manter se já estiver) |
| **Salvar** orçamento | `BudgetRepositoryImpl.saveBudget()` | `selectBudget.value = budget;` (atualiza total e ID automaticamente) |
| **Sair** do fluxo de orçamento | `BudgetListView` (onPop / dispose do fluxo) | `budgetRepo.selectBudget.value = null;` |
| **Duplicar** orçamento | `BudgetListViewModel.duplicateEvent()` | Limpa para evitar levar ID antigo: `selectBudget.value = null;` |

---

## 3. Passo a Passo de Implementação

> **Regras do projeto aplicadas**:  
> 1. Ponytail: não crie wrapper, datasource extra, ou usecase que ninguém pediu.  
> 2. Repository é singleton; ViewModel é factory.  
> 3. A interface do Repository (`domain/repository/`) deve ser atualizada antes da implementação.  
> 4. Toda operação async na UI passa por `Command`.  
> 5. Tipos primitivos/JSON no DataSource; models/entities no Repository.

### 3.1 Fase 1 — Preparar o contrato (`domain`)

**Arquivo**: `lib/modules/budget/domain/repository/budget_repository.dart`

Adicionar ao `abstract class BudgetRepository extends ChangeNotifier`:

```dart
  /// Orçamento ativamente selecionado (substitui global_uid_budget.dart).
  ValueNotifier<CustomerInfo?> get selectBudget;
  set selectBudget(ValueNotifier<CustomerInfo?> value);

  /// Limpa o orçamento selecionado.
  void clearSelectBudget();
```

> Nota: `selectedBudget` (getter simples `CustomerInfo?`) já existe e pode coexistir temporariamente. Após migração completa, avaliar se `selectedBudget` pode ser derivado de `selectBudget.value` para evitar duplicação de estado. **Pelo ponytail**, mantenha ambos se remover exigir refatorar 10+ arquivos adicionais.

### 3.2 Fase 2 — Implementar no `BudgetRepositoryImpl`

**Arquivo**: `lib/modules/budget/data/repository/budget_repository_impl.dart`

1. Remover `import ...global_uid_budget.dart`.
2. Adicionar o `ValueNotifier` e seus getters/setters.
3. Substituir toda escrita nas globais por atualização do `selectBudget`:
   - `saveBudget()`: `selectBudget.value = budget;`
   - `duplicateBudget()` (final): `selectBudget.value = null;` (ou `newBudget` se quiser manter o novo selecionado — discutir regra de negócio).

### 3.3 Fase 3 — Fase 1 do consumo interno do módulo `budget`

#### 3.3.1 `budget_list_view_model.dart`

- Remover import de `global_uid_budget`.
- `duplicateEvent()`: em vez de `budget.IDORCAMENTO = ''`, usar `_budgetRepository.selectBudget.value = null;`.
- `getInformationOrcamento()` (e métodos similares): não precisa mais consultar a global.

#### 3.3.2 `budget_list_view.dart`

- Remover import de `global_uid_budget`.
- Nas funções de `onTap`/`onLongPress` onde se fazia `budget.IDORCAMENTO = item.id` ou `budget.IDORCAMENTO = ''`:
  - **Selecionar**: `_budgetRepository.selectBudget.value = item;`
  - **Limpar ao sair**: `_budgetRepository.selectBudget.value = null;`

#### 3.3.3 `budget_creator_view_model.dart`

- Remover import de `global_uid_budget`.
- `_applyToGlobals()`: **deletar método inteiro**. O `CustomerInfo` já é o objeto; não precisa replicar campo a campo numa global.
- `saveBudget()`:
  ```dart
  Future<void> saveBudget(CustomerInfo budget) async {
    final result = await _budgetRepository.saveBudget(budget);
    // O próprio repository já atualiza selectBudget.value.
  }
  ```
- `init()`: remover chamada a `_applyToGlobals(item);`.

#### 3.3.4 `budget_list_items_view_model.dart` e `budget_list_items_view.dart`

- `budget_list_items_view_model.dart`:
  - Remover import de `global_uid_budget`.
  - Onde faz `budget.VALORTOTAL = totalBudget`, usar `_budgetRepository.selectBudget.value = _budgetRepository.selectBudget.value?.copyWith(totalValue: totalBudget);` ou, se `CustomerInfo` não for immutable, atualizar o campo e notificar o ValueNotifier:
    ```dart
    _budgetRepository.selectBudget.value?.totalValue = totalBudget;
    _budgetRepository.selectBudget.notifyListeners(); // se CustomerInfo não for ValueNotifier-aware
    ```
    **Alternativa mais limpa (recomendada)**: como `selectBudget` é `ValueNotifier`, atribuir um novo objeto força notificação:
    ```dart
    final current = _budgetRepository.selectBudget.value;
    if (current != null) {
      current.totalValue = totalBudget;
      _budgetRepository.selectBudget.value = current; // re-atribui para notificar
    }
    ```

- `budget_list_items_view.dart`:
  - Remover import de `global_uid_budget`.
  - `fromListItem`: em vez de `budget.fromListItem = true/false`, passar via argumento de rota (`Navigator.push(..., arguments: true/false)`) ou usar estado local da ViewModel.  
    **Decisão**: como `fromListItem` é flag de UI, crie um getter/setter na `BudgetListItemsViewModel` (ex: `bool launchedFromListItem`) e limpe no `dispose()`.

### 3.4 Fase 4 — Módulos que leem `IDORCAMENTO` (produto, PDF)

#### 3.4.1 `product_price_list_view_model.dart`

- Remover import de `global_uid_budget`.
- Onde usava `budget.IDORCAMENTO ?? ''`, usar `_budgetRepository.selectBudget.value?.id ?? ''`.
- Se `selectionMode && item?.id != null`: o `item` já é passado pelo construtor; nada muda.

#### 3.4.2 `product_price_creator_view_model.dart`

- Remover import de `global_uid_budget`.
- `fromListItem`: virar campo local da ViewModel ou receber via argumento de construtor/rota.
- `budget.IDORCAMENTO ?? ''` → `_budgetRepository.selectBudget.value?.id ?? ''`.

#### 3.4.3 PDF UseCases (`pdf_generate_*_usecase.dart`)

- Esses usecases hoje usam `budget.IDORCAMENTO` para nomear o arquivo PDF e `budget.googleAuth`.
- **Decisão**: passar o `CustomerInfo` como parâmetro do usecase em vez de ler global.  
  Exemplo de assinatura atual → nova:
  ```dart
  // Antes
  Future<String> execute();
  // Depois
  Future<String> execute({required CustomerInfo? selectedBudget});
  ```
  Ou, se o usecase já recebe dados suficientes, simplesmente o campo `id` do orçamento.
- Remover import de `global_uid_budget`.

#### 3.4.4 `pdf_budget_view_model.dart`

- Remover import de `global_uid_budget`.
- Substituir `budget.IDORCAMENTO ?? ''` por `_budgetRepository.selectBudget.value?.id ?? ''`.

#### 3.4.5 `pdf_receipt_view_model.dart`

- Semelhante ao acima; usar `selectBudget.value?.id`.

### 3.5 Fase 5 — Módulos `payment` e `receipt` (campo `IDRECIBO`)

#### 3.5.1 Decisão sobre `IDRECIBO`

O `IDRECIBO` pertence ao domínio `receipt`. A solução correta é criar um `selectedReceipt` no `ReceiptRepository` (mesmo padrão `ValueNotifier<ReceiptModel?>`), mas isso expande o escopo.

**Alternativa dentro do escopo atual**:
- Criar um `ValueNotifier<String?> selectedReceiptId` também no `ReceiptRepository` ou manter como estado local nas ViewModels de `payment` e `receipt`.
- **Pelo ponytail**, como apenas 3 arquivos usam `IDRECIBO`, a abordagem de estado local é aceitável a curto prazo:
  - `ReceiptListViewModel` e `PaymentListViewModel` recebem o receipt selecionado como parâmetro na navegação.
  - Se precisam persistir entre telas, passam via `Navigator.push(arguments: ...)`.

**Arquivos a ajustar**:
- `receipt_list_view_model.dart` — remover `budget.IDORCAMENTO = ...` e `budget.IDRECIBO = ...`; usar `_budgetRepository.selectBudget.value = item` e passar o receipt ID via rota/estado local.
- `payment_list_view_model.dart` — mesmo padrão.
- `payment_remote_datasource.dart` — hoje lê `budget.IDORCAMENTO` e `budget.IDRECIBO` para montar path do Firestore. Isso é **arquiteturalmente errado**: DataSource não deve ler estado global.  
  **Correção**: os métodos do datasource devem receber `budgetId` e `receiptId` como parâmetros `String`. A ViewModel ou Repository que os chama deve extrair esses IDs do estado correto.
- `receipt_remote_datasource.dart` — mesma correção.

### 3.6 Fase 6 — `chat_assistant`

**Arquivo**: `lib/modules/chat_assistant/data/repository/chat_budget_repository_impl.dart`

- Remover import de `global_uid_budget`.
- Onde faz `budgetGlobals.VALORTOTAL = total;` e `budgetGlobals.IDORCAMENTO = finalized.id;`, usar acesso ao `BudgetRepository` (injetado ou via `getIt`) e atualizar `selectBudget.value`.

> **Nota**: O `ChatBudgetRepositoryImpl` está na camada `data`. Se ele não tem acesso ao `BudgetRepository`, prefira notificar via callback ou evento, ou injetar o `BudgetRepository` no construtor. Isso é aceitável porque ambos são repositórios de **feature** (não core).

### 3.7 Fase 7 — `core/notification`

**Arquivo**: `lib/modules/core/notification/data/repository/notification_repository_impl.dart`

- Hoje faz `budget.IDORCAMENTO = budgetId;`.
- **Problema**: `notification` é módulo `core`. Ele não deve depender de estado de feature.
- **Solução**: o método que precisa do `budgetId` deve recebê-lo como parâmetro `String`, não ler de global. Ajustar a interface e todos os callers.

### 3.8 Fase 8 — Limpeza final

1. Deletar `lib/shared/common/constants/global_uid_budget.dart`.
2. Rodar `flutter analyze` e corrigir imports quebrados.
3. Rodar build/run para testar fluxos críticos:
   - Criar orçamento → salvar → listar itens.
   - Duplicar orçamento.
   - Gerar PDF de orçamento.
   - Criar recibo/pagamento a partir de orçamento.
   - Chat assistant criar orçamento.

---

## 4. Mapeamento de Alterações por Arquivo

| # | Arquivo | Ação | Detalhe |
|---|---------|------|---------|
| 1 | `budget/domain/repository/budget_repository.dart` | Adicionar | `ValueNotifier<CustomerInfo?> selectBudget` (getter + setter) + `clearSelectBudget()` |
| 2 | `budget/data/repository/budget_repository_impl.dart` | Alterar/Remover | Implementar `selectBudget`; remover `global_uid_budget`; ajustar `saveBudget` e `duplicateBudget` |
| 3 | `budget/budget_list/presenter/budget_list_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `_budgetRepository.selectBudget` |
| 4 | `budget/budget_list/presenter/budget_list_view.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `_budgetRepository.selectBudget.value = ...` e `= null` |
| 5 | `budget/budget_creator/presenter/budget_creator_view_model.dart` | Alterar/Remover | Deletar `_applyToGlobals`; remover `global_uid_budget`; confiar no `selectBudget` do repo |
| 6 | `budget/budget_list_items/presenter/budget_list_items_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; atualizar total via `selectBudget.value` |
| 7 | `budget/budget_list_items/presenter/budget_list_items_view.dart` | Alterar/Remover | Remover `global_uid_budget`; `fromListItem` → estado local/argumento de rota |
| 8 | `product/product_price_list/presenter/product_price_list_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `_budgetRepository.selectBudget.value?.id` |
| 9 | `product/product_price_creator/presenter/product_price_creator_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `selectBudget`; `fromListItem` → estado local |
| 10 | `pdf/pdf_budget/presenter/pdf_budget_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `selectBudget.value?.id` |
| 11 | `pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; usar `selectBudget.value?.id` |
| 12 | `pdf/domain/usecase/pdf_generate_budget_usecase.dart` | Alterar | Remover `global_uid_budget`; receber `CustomerInfo` ou `id` via parâmetro |
| 13 | `pdf/domain/usecase/pdf_generate_professional_usecase.dart` | Alterar | Idem |
| 14 | `pdf/domain/usecase/pdf_generate_receipt_usecase.dart` | Alterar | Idem |
| 15 | `pdf/domain/usecase/pdf_generate_executive_usecase.dart` | Alterar | Idem |
| 16 | `payment/payment_list/presenter/payment_list_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; `IDORCAMENTO` → `selectBudget`; `IDRECIBO` → estado local/rota |
| 17 | `payment/data/datasource/payment_remote_datasource.dart` | Alterar | Remover `global_uid_budget`; receber `budgetId` e `receiptId` como parâmetros |
| 18 | `receipt/receipt_list/presenter/receipt_list_view_model.dart` | Alterar/Remover | Remover `global_uid_budget`; `IDORCAMENTO` → `selectBudget`; `IDRECIBO` → estado local/rota |
| 19 | `receipt/data/datasource/receipt_remote_datasource.dart` | Alterar | Remover `global_uid_budget`; receber `budgetId` como parâmetro |
| 20 | `chat_assistant/data/repository/chat_budget_repository_impl.dart` | Alterar/Remover | Remover `global_uid_budget`; atualizar `selectBudget` via `BudgetRepository` injetado |
| 21 | `core/notification/data/repository/notification_repository_impl.dart` | Alterar/Remover | Remover `global_uid_budget`; receber `budgetId` como parâmetro |
| 22 | `shared/common/constants/global_uid_budget.dart` | **Deletar** | Arquivo inteiro |

---

## 5. Recomendações de Implementação Ordenadas (Menor Risco)

> Execute em lotes para manter o app compilável a cada lote.

### Lote A — Fundação (compila, não muda comportamento ainda)
1. Adicionar `selectBudget` na interface e implementação do `BudgetRepository`.
2. Inicializar `selectBudget.value = null` em todos os pontos onde hoje se faz `budget.IDORCAMENTO = ''` (views de listagem), mas **ainda manter a global**.

### Lote B — Módulo `budget` (feature principal)
3. Refatorar `budget_list_view`, `budget_list_view_model`, `budget_creator_view_model`, `budget_list_items_view/model` para consumir `selectBudget`.
4. **Remover** escrita/leitura da global nesses arquivos.

### Lote C — Módulos satélites (`product`, `pdf`, `chat_assistant`)
5. Refatorar `product_price_list/creator`.
6. Refatorar PDFs: ajustar ViewModels e UseCases para receber `CustomerInfo` via parâmetro;
7. Refatorar `chat_budget_repository_impl`.

### Lote D — Módulos `payment` e `receipt`
8. Ajustar datasources para receber IDs via parâmetro.
9. Ajustar ViewModels para usar `selectBudget` e estado local para `IDRECIBO`.

### Lote E — `core/notification` e limpeza
10. Ajustar `notification_repository_impl` para receber `budgetId`.
11. Deletar `global_uid_budget.dart`.
12. Rodar `flutter analyze` e testar.

---

## 6. Notas sobre `fromListItem`

`fromListItem` é uma flag booleana que diz se o usuário entrou na tela de produtos **vindo da lista de itens do orçamento** (para adicionar item) ou **vindo do menu principal** (apenas gerenciar tabela de preços).

Essa informação é de **navegação/estado de tela**, não de domínio. Portanto:

- Não deve ir para `BudgetRepository`.
- Deve ser passada como argumento de rota (`Navigator.pushNamed(..., arguments: true)`) ou como parâmetro no construtor da ViewModel.
- Exemplo na `ProductPriceListViewModel`:
  ```dart
  ProductPriceListViewModel({this.item, this.fromMenu = false, this.selectionMode = false, this.fromListItem = false});
  ```

---

## 7. Notas sobre `IDRECIBO`

Se futuramente o time quiser eliminar completamente variáveis globais de recibo, o caminho correto é replicar o mesmo padrão `ValueNotifier<ReceiptModel?>` no `ReceiptRepository`. Este plano **não cria** esse refactor para manter o escopo enxuto (ponytail), mas documenta a dívida técnica.

---

## 8. Checklist de Validação

- [ ] `global_uid_budget.dart` foi deletado.
- [ ] Nenhum arquivo em `lib/` importa `global_uid_budget`.
- [ ] `BudgetRepository.selectBudget` é `ValueNotifier<CustomerInfo?>`.
- [ ] Ao tocar num orçamento na lista, `selectBudget.value` é populado.
- [ ] Ao sair do fluxo de orçamento (voltar para lista/dashboard), `selectBudget.value` é `null`.
- [ ] `budget_creator` não replica campo a campo para global.
- [ ] `payment_remote_datasource` e `receipt_remote_datasource` não acessam estado global.
- [ ] `flutter analyze` passa sem erros.
- [ ] Fluxo de criação/edição/duplicação de orçamento funciona.
- [ ] Fluxo de gerar PDF funciona.
- [ ] Fluxo de adicionar produto ao orçamento funciona.
- [ ] Fluxo de recibo/pagamento funciona.

---

*Plano criado seguindo `.pi/PROJECT_STRUCTURE.md`: ponytail, MVVM+Clean, ChangeNotifier, e separação strict entre DataSource (primitivos/json) e Repository (models/estado).*