# Plano — Seleção de itens da Lista de Preço (modal-picker)

> Segue `.pi/ARCHITECTURE.md` (Ponytail §0, Componentes §2.1, Command §4.4,
> UseCases §6, Cores §15, Feedback §18, Modal-tela §19).

---

## 1. Problema

Hoje, em **Itens do orçamento → "Adicionar item" → "Selecionar da lista de preço"**,
o app faz `Navigator.push` para a **tela cheia** `ProductPriceListView`, a mesma
usada pelo menu de configurações. Essa tela mistura 3 papéis:

1. gerenciar a lista de preço (criar/editar/excluir — FAB "Novo Item", long-press);
2. selecionar itens para o orçamento (checkbox + quantidade);
3. revisar um carrinho num **segundo** modal ("Carrinho de produtos" → "Adicionar").

Resultado: o usuário não sabe se está editando a lista ou escolhendo itens,
precisa de 2 passos para confirmar ("Ver carrinho" → "Adicionar"), e a
quantidade aceita `0` (`double.tryParse(...) ?? 0`, sem validação).

## 2. Comportamento desejado

| # | Regra |
|---|-------|
| 1 | Fluxo "Criar novo item" do orçamento **não muda**. |
| 2 | "Selecionar da lista de preço" abre um **modal-picker** (não mais tela) com **67% da altura** da tela. |
| 3 | Picker é **somente seleção**: sem "Novo Item", sem editar ao tocar, sem long-press/excluir. |
| 4 | Tocar num item **não selecionado** abre o input de quantidade (igual hoje). |
| 5 | Quantidade **nunca pode ser 0** (nem vazia, negativa ou inválida) — erro inline, modal de quantidade continua aberto. |
| 6 | Tocar/desmarcar um item **já selecionado** remove-o do carrinho direto na lista (sem modal de carrinho). |
| 7 | Rodapé mantém o visual atual (ícone, "Total dos itens", valor / N itens). |
| 8 | Botão do rodapé muda de **"Ver carrinho"** para **"Adicionar tudo"**, que faz exatamente o que o "Adicionar" do modal "Carrinho de produtos" faz hoje: salva todos os itens no orçamento, fecha o picker e a tela de itens recarrega. |
| 9 | Modal **"Carrinho de produtos"** é **descontinuado** neste fluxo. |
| 10 | Tela de lista de preço do **menu** (`fromMenu: true`) e do **chat** continua como gestão (criar/editar/excluir). |

## 3. Decisões de arquitetura

- **Modal complexo é tela (§19)**: o picker tem estado (busca, carrinho,
  total), chama UseCase e tem vários widgets → nova pasta
  `product/presenter/product_price_picker/` com View + ViewModel + `components/`.
- **Quem salva é o modal (§19.3 r5/r6)**: o picker persiste e fecha com
  `pop(true)`; `BudgetListItemsView` só recarrega e mostra snackbar.
- **Regra de negócio = UseCase**: "converter carrinho em `ItemsBudget` e
  salvar no orçamento" hoje está duplicado em `saveCart`/`finalizeSelection`
  do VM → vira `AddPriceItemsToBudgetUseCase` (domínio do módulo `budget`,
  que é o dono de `ItemsBudget` — §10). Chamada externa continua só no
  DataSource via `BudgetRepository.saveBudgetItem`.
- **Validação de quantidade**: o `TextInputBottomModalWidget` compartilhado é
  genérico; em vez de enfiar regra nele, criar um modal de quantidade
  próprio do picker com erro inline (componente simples, sem VM, devolve
  `double?` já validado `> 0`). A regra `qtd > 0` fica no VM do picker
  (`validateQuantity`) — é validação de formulário (§3.2), não persistência.
- **Altura 67%**: `AppBottomModal` hoje tem `maxHeightFactor = 0.8` fixo.
  Adicionar parâmetro opcional `heightFactor` (default 0.8) e, para o
  picker, altura **fixa** de 0.67 (não "máxima"), para a lista não "pular"
  enquanto filtra.
- **Ponytail**: deletar do `ProductPriceListViewModel` tudo que só servia ao
  modo seleção/carrinho (`selectionMode`, `finalizeSelection`, `saveCart`,
  `openCartModal`, `editCartQty`, `removeFromCart`, `addItems`, `cartTotal`,
  carga de itens do orçamento em `inicialData`) e o rodapé da View.

## 4. Estrutura de arquivos

```
lib/modules/budget/
└── domain/usecase/
    └── add_price_items_to_budget_usecase.dart        # NOVO

lib/modules/product/presenter/
├── product_price_picker/                             # NOVO (modal-tela)
│   ├── product_price_picker_view.dart                # View + showProductPricePickerBottomModal()
│   ├── product_price_picker_view_model.dart          # busca, carrinho, total, Command addAll
│   └── components/
│       ├── product_price_picker_card.dart            # card com check (selecionado/não)
│       ├── product_price_picker_footer.dart          # rodapé "Total dos itens" + "Adicionar tudo"
│       ├── product_price_picker_search_field.dart    # busca
│       └── product_price_picker_quantity_bottom_modal_widget.dart  # qtd com erro inline (> 0)
├── product_price_list/                               # ENXUGAR (só gestão)
│   ├── product_price_list_view.dart
│   └── product_price_list_view_model.dart
└── strings/product_pt_string.dart                    # + strings do picker

lib/shared/common/widgets/modals/
└── app_bottom_modal_widget.dart                      # + heightFactor opcional
```

## 5. Passo a passo

### Passo 1 — `AppBottomModal`: altura configurável
- Adicionar `final double? heightFactor;` (null = comportamento atual, máx. 0.8).
- Quando informado, usar `SizedBox(height: (h - teclado) * heightFactor)`.
- Não muda nenhum modal existente.

### Passo 2 — UseCase `AddPriceItemsToBudgetUseCase` (módulo `budget`)
```dart
class AddPriceItemsToBudgetUseCase {
  AddPriceItemsToBudgetUseCase(this._budgetRepository);
  final BudgetRepository _budgetRepository;

  Future<Result<void>> call(String budgetId, List<ItemsBudget> items) async {
    // valida: lista não vazia; todo item com quantity > 0
    // salva cada item via _budgetRepository.saveBudgetItem(budgetId, item)
    // retorna Ok / Error (sem try/catch na VM)
  }
}
```
- Registrar em `budget_binds.dart`.
- Recebe `ItemsBudget` (o picker converte via `ProductPriceModel.toItemsBudget()`
  — conversão pura, permitida fora de usecase).

### Passo 3 — `ProductPricePickerViewModel`
Estado:
- `searchController`, `_all`, `isLoading`, `List<ItemsBudget> cart` (ou
  `Map<String idProduto, ProductPriceModel>` para lookup O(1)).
- getters: `found`, `isSelected(item)`, `cartTotal`, `cartCount`,
  `canAddAll => cart.isNotEmpty`.

Ações:
- `load()` → `ProductPriceRepository.fetchProducts()` (cópia da lista).
  **Não** pré-carrega itens já salvos no orçamento (hoje isso causa
  duplicação ao salvar de novo — carrinho começa vazio).
- `String? validateQuantity(String raw)` → `null` se `> 0`, senão mensagem
  (`ProductPtString.qtyMustBePositive`). Aceita vírgula.
- `select(item, qtd)` → adiciona ao carrinho com `total = qtd * preco`.
- `unselect(item)` → remove do carrinho (é o "desflegar").
- `addAll = Command0<void>(_addAll)` → chama o UseCase com `budgetId` e
  `cart` convertido.

### Passo 4 — `ProductPricePickerView` (modal-tela)
- `StatefulWidget`, cria/descarta VM, `AnimatedBuilder` (§19.3 r1).
- `AppBottomModal(title: 'Lista de preço', heightFactor: 0.67, ...)`:
  - topo: `ProductPricePickerSearchField`;
  - meio: `ListView` de `ProductPricePickerCard`;
  - rodapé fixo: `ProductPricePickerFooter` (só aparece com `cart.isNotEmpty`,
    visual igual ao `BottomAppBar` atual — mover cores hardcoded
    `0xFF161622`/`0xFF00BFA5` para `colors.dart` §15).
- Tap no card:
  - não selecionado → `showProductPricePickerQuantityBottomModal(...)` →
    se retornou valor válido, `vm.select(...)`;
  - selecionado → `vm.unselect(...)`.
- "Adicionar tudo" → `vm.addAll.execute()`; ouvir o Command:
  - sucesso → `Navigator.pop(context, true)`;
  - erro → modal **continua aberto** com o carrinho intacto + snackbar de
    erro (§18) com `ProductPtString.cartAddError`.
- Botão desabilitado + "Adicionando..." enquanto `addAll.running`.
- Helper no mesmo arquivo:
```dart
Future<bool> showProductPricePickerBottomModal(
  BuildContext context, {required String budgetId}) async { ... ?? false }
```

### Passo 5 — Componentes (`components/`, 1 por arquivo, público, sem VM)
- `ProductPricePickerCard`: reusa layout do `ProductPriceCard` (descrição,
  pílula de categoria, preço); trailing = check marcado/desmarcado; quando
  selecionado mostra `qtd × preço = total`. Props: `item`, `selected`,
  `quantity`, `moneyConvert`, `onTap`.
- `ProductPricePickerFooter`: props `total`, `count`, `loading`,
  `onAddAll`. Botão "Adicionar tudo".
- `ProductPricePickerSearchField`: props `controller`, `onChanged`.
- `ProductPricePickerQuantityBottomModalWidget` (modal **simples**): campo
  numérico com `autofocus`, `errorText` inline, recebe
  `String? Function(String) validator` e devolve `double?`. Não fecha
  enquanto o validador retornar erro (§17 UX de formulários).

### Passo 6 — Ligar no orçamento (`BudgetListItemsView`)
```dart
Future<void> _openPriceList() async {
  final added = await showProductPricePickerBottomModal(
    context, budgetId: widget.item.id!);
  if (!added || !mounted) return;
  await _viewModel.getListItens();
  if (!mounted) return;
  await _displayAlert.notificationNotCloseScreen(
    context, ProductPtString.doneTitle, ProductPtString.cartAddSuccess);
}
```
- `_addItem` e `_showProductPriceCreatorBottomModal` **não mudam**.
- Remover import de `ProductPriceListView` da tela de itens.

### Passo 7 — Enxugar `ProductPriceListView`/`ViewModel` (só gestão)
Remover:
- `selectionMode`, `item`, `addItems`, `cartTotal`, `toggleSelectProduct`,
  `removeFromCart`, `editCartQty`, `openCartModal`, `saveCart`,
  `finalizeSelection`, aviso de carrinho em `onBack`, carga de itens do
  orçamento em `inicialData`, dependência de `BudgetRepository`.
- `_buildBottomAppBar` inteiro e o `checkBoxProductVisible` do carrinho no
  `ProductPriceCard` (trailing de carrinho some; fica só checkbox de excluir).
- Construtor fica `ProductPriceListView({bool fromMenu})`; ajustar chamadas
  em `main_config_menu_view_model.dart`, `chat_assistant_view.dart` e
  `product_routes.dart`.
- Revisar `openCreator(fromListItem: ...)` — com `item` removido passa a ser
  sempre `false` (criar pela lista de preço não vincula a orçamento; §14
  continua valendo só no fluxo "Criar novo item" do orçamento).

### Passo 8 — Descontinuar "Carrinho de produtos"
- Remover `ProductPtString.cartTitle`, `cartButton`, `cartWarningTitle`,
  `cartWarning` se não tiverem mais uso.
- `ItemsListBottomModalWidget` (shared): checar `grep`; se o carrinho era o
  único uso, **deletar** o arquivo (Ponytail: deletar > adicionar).

### Passo 9 — Strings (`product_pt_string.dart`)
```
pickerTitle        = 'Lista de preço'
pickerAddAll       = 'Adicionar tudo'
pickerAdding       = 'Adicionando...'
pickerEmpty        = 'Nenhum item na lista de preço'
qtyMustBePositive  = 'A quantidade deve ser maior que zero'
```
Labels apenas — nenhum valor persistido muda (regra i18n).

## 6. Verificação

- [ ] Orçamento → Adicionar item → "Criar novo item": igual a antes.
- [ ] "Selecionar da lista de preço": modal sobe com ~67% da tela, sem
      "Novo Item", sem editar/excluir.
- [ ] Tocar item → digitar `0`, vazio, `-1`, `abc` → erro inline, não fecha.
- [ ] Digitar `2,5` → item marcado, rodapé mostra total e "1 item".
- [ ] Tocar no item marcado → desmarca, total recalcula; carrinho vazio
      esconde o rodapé.
- [ ] Busca mantém seleção ao filtrar/limpar.
- [ ] "Adicionar tudo" → loading no botão → modal fecha → lista de itens e
      total do orçamento atualizados + snackbar de sucesso.
- [ ] Sem internet → snackbar de erro, modal aberto, carrinho preservado.
- [ ] Menu → Lista de preço: criar/editar/excluir funcionam; sem rodapé de
      carrinho.
- [ ] Chat assistente → abrir lista de preço: idem acima.
- [ ] `flutter analyze` limpo; teste unitário do UseCase (lista vazia,
      qtd 0 → Error; caso feliz chama `saveBudgetItem` N vezes) e do
      `validateQuantity`.

## 7. Fora de escopo

- Editar quantidade de item já selecionado dentro do picker (hoje feito no
  modal do carrinho, que sai). Para trocar a quantidade: desmarcar e marcar
  de novo, ou editar depois na tela de itens (`budget_item_quantity`).
- Mudanças no fluxo "Criar novo item".
