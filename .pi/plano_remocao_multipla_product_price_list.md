# Plano de Implementação — Remoção Múltipla na Lista de Preço

> Modelo alvo: `z-ai/glm-5.3-flash:batch`  
> Base: `@.pi/ARCHITECTURE.md` (MVVM + ChangeNotifier, regra *ponytail full*)  
> Referência visual/comportamental: `budget_list_items_view.dart` e `budget_list_items_delete_bottom_modal_widget.dart`

---

## 1. Objetivo

Replicar na `ProductPriceListView` o fluxo de remoção múltipla já existente no `BudgetListItemsView`:

1. **Long-press** em um item ativa o modo remoção.
2. No modo remoção, o checkbox de exclusão aparece no **lado esquerdo** (leading) do card.
3. O checkbox de adicionar ao orçamento permanece no **lado direito** (trailing).
4. O FAB principal vira o **botão de lixeira com badge** contendo a quantidade de itens marcados.
5. Ao tocar no FAB de lixeira, abre um **bottom modal próprio** para confirmar/excluir os itens, igual ao modal do orçamento.

---

## 2. Diagnóstico rápido do estado atual

O `ProductPriceListViewModel` já possui a maior parte da lógica:

- `deleteItems`, `deleteVisible`, `checkBoxAppear`
- `onLongPress()`, `toggleDeleteCheckbox()`, `removeFromDeleteList()`
- `deleteSelected()` já persiste a exclusão no Firebase via `_productRepository.deleteProduct()`
- `openDeleteModal()` abre o modal, mas usando o modal genérico `ItemsListBottomModalWidget`

O que falta é:

- Checkbox de delete no **leading** do card.
- FAB de lixeira com badge no lugar do botão “Novo Item”.
- Bottom modal específico para confirmação de remoção de produtos, espelhado no modal do orçamento.

---

## 3. Arquivos a criar

### 3.1 Card de item a ser removido

**Caminho:**  
`lib/modules/product/presenter/product_price_list/components/card/product_price_delete_item_card.dart`

**Responsabilidade:**  
Renderizar um `ProductPriceModel` dentro do modal de exclusão, com descrição, categoria, preço e botão “X” para desmarcar.

**Campos exibidos:**
- Descrição
- Categoria
- Preço unitário
- Ícone de remoção (desmarca o item da lista de exclusão)

**Observação:** diferente do orçamento, itens da lista de preço não possuem quantidade, então o card será mais enxuto, sem linha de quantidade/total.

---

### 3.2 Bottom modal de confirmação de remoção

**Caminho:**  
`lib/modules/product/presenter/product_price_list/components/modals/product_price_list_delete_bottom_modal_widget.dart`

**Responsabilidade:**  
Espelhar `BudgetListItemsDeleteBottomModalWidget`, mas trabalhando com `List<ProductPriceModel>`.

**Contrato:**
```dart
final List<ProductPriceModel> deleteItems;
final ConvertCoinRepository moneyConvert;
final void Function(ProductPriceModel item) onRemove;
final Future<void> Function() onConfirm;
```

**Comportamento:**
- Mantém cópia local dos itens (`setState` interno) para atualização em tempo real ao desmarcar.
- Botão principal: `"EXCLUIR ITENS"` (usar `ProductPtString.deleteButton`).
- Ao confirmar: exibe loading, chama `onConfirm`, fecha modal, notifica sucesso/erro.
- Se a lista ficar vazia, exibe mensagem `"Nenhum item selecionado."`.

**Base visual:** reutilizar `AppBottomModal`.

---

## 4. Arquivos a alterar

### 4.1 `product_price_card.dart`

**Mudança:** mover o checkbox de remoção para o `leading`.

**Layout atual:** todos os controles ficam no trailing.

**Novo layout:**
```text
[Checkbox delete]  [Descrição / Categoria / Preço]  [Checkbox carrinho/círculo]
     leading                centro (Expanded)                  trailing
```

**Regras de renderização:**
- Se `checkBoxAppear == true`: exibir checkbox de delete no **leading**.
- Se `checkBoxAppear == false` e `checkBoxProductVisible == true` e `!fromMenu`: exibir checkbox de adicionar ao orçamento no **trailing**.
- Caso contrário: exibir o círculo vazio no **trailing**.

> Isso satisfaz o requisito: “lado direito mantém o que está fazendo hoje e lado esquerdo remove”.

---

### 4.2 `product_price_list_view_model.dart`

**Mudança:** trocar o modal genérico pelo modal específico de produtos.

**Método a alterar:** `openDeleteModal(BuildContext context)`

**Novo comportamento:**
- Abrir `showModalBottomSheet` com `ProductPriceListDeleteBottomModalWidget`.
- `onRemove`: chamar `removeFromDeleteListByItem(ProductPriceModel item)` (novo método) ou adaptar `removeFromDeleteList`.
- `onConfirm`: chamar `deleteSelected(context)`.

**Ajuste auxiliar:** criar/remover itens pelo objeto em vez de índice:

```dart
void removeFromDeleteListByItem(ProductPriceModel item) {
  deleteItems.remove(item);
  final i = _all.indexWhere((e) => e.id == item.id);
  if (i != -1) {
    _all[i] = _all[i].copyWith(checkBox: false);
  }
  if (deleteItems.isEmpty) {
    deleteVisible = false;
    checkBoxAppear = false;
    checkBoxProductVisible = true;
  }
  notifyListeners();
}
```

> Manter `removeFromDeleteList(int index)` caso outro chamador use, ou substituí-lo se não houver outros usos.

---

### 4.3 `product_price_list_view.dart`

**Mudanças:**

#### A) Remover o `BottomAppBar` de exclusão

Atualmente existe este bloco:
```dart
if (_viewModel.deleteVisible && _viewModel.deleteItems.isNotEmpty) {
  return BottomAppBar(... botão "Excluir itens" ...);
}
```

Esse bloco deve ser **removido**, pois a ação de exclusão passará para o FAB.

#### B) Alterar `_buildFloatingActionButton()`

Comportamento atual: retorna apenas o FAB “Novo Item” (escondido em `selectionMode`).

Novo comportamento:
```dart
if (_viewModel.selectionMode) return SizedBox.shrink();

if (_viewModel.deleteVisible) {
  return FloatingActionButton.extended(
    heroTag: 'delete',
    onPressed: () => _viewModel.openDeleteModal(context),
    backgroundColor: buttonColor,
    icon: const Icon(Icons.delete_outline_rounded, color: Colors.black),
    label: const Text('Remover todos', ...),
  ) wrapped com Badge mostrando _viewModel.deleteItems.length;
}

return FloatingActionButton.extended(
  heroTag: 'adicionar_novo_item',
  onPressed: () => _viewModel.addNew(context),
  ...
);
```

**Badge:** usar o mesmo pacote `badges` já utilizado em `budget_list_items_view.dart`.

#### C) Ajuste no `RefreshIndicator`

Em `budget_list_items_view.dart`, o refresh limpa a seleção de delete. Avaliar se o mesmo comportamento é desejável aqui. Recomendo adicionar:
```dart
onRefresh: () async {
  await _viewModel.refresh();
  _viewModel.clearDeleteState(); // se não existir, criar
}
```

> Isso evita itens fantasmas marcados após recarregar a lista.

---

## 5. Fluxo de interação final

1. Usuário segura um card → `onLongPress` → `checkBoxAppear = true`, `deleteVisible = true`.
2. Checkbox de delete aparece no **lado esquerdo** do card; checkbox de carrinho continua no **direito**.
3. Usuário toca no checkbox esquerdo → item entra em `deleteItems`.
4. FAB “Novo Item” é substituído pelo FAB de lixeira com badge vermelha indicando a quantidade.
5. Usuário toca no FAB de lixeira → abre `ProductPriceListDeleteBottomModalWidget`.
6. No modal, pode desmarcar itens individualmente (atualização local em tempo real).
7. Confirma → `deleteSelected()` remove do Firebase, limpa o estado e recarrega a lista.

---

## 6. Checklist de entrega

- [ ] `product_price_delete_item_card.dart` criado e usando `ProductPriceModel`.
- [ ] `product_price_list_delete_bottom_modal_widget.dart` criado, espelhado no modal do orçamento.
- [ ] `product_price_card.dart` com checkbox de delete no leading.
- [ ] `product_price_list_view_model.dart` usando o novo modal e métodos de remoção por objeto.
- [ ] `product_price_list_view.dart` com FAB de lixeira/badge e sem o BottomAppBar de exclusão.
- [ ] Strings já existentes em `ProductPtString` reutilizadas (`deleteListTitle`, `deleteButton`, `deleteSuccess`, `deleteError`, `doneTitle`, `errorTitle`).
- [ ] `pubspec.yaml` já contém `badges` (verificar apenas, pois budget já o utiliza).
- [ ] Testar: long-press, selecionar múltiplos, desmarcar no modal, confirmar exclusão, cancelar e voltar ao estado normal.

---

## 7. Notas de arquitetura

- **Ponytail full:** não criar datasource/repository/usecase novo. A exclusão já passa por `_productRepository.deleteProduct()`, portanto a mudança é apenas de UI/estado.
- **ViewModel:** continua sendo a única fonte de estado; a View apenas reage via `AnimatedBuilder`.
- **Modal:** é um componente puro de apresentação; a lógica de confirmação continua no `ViewModel`.
- **Card:** permanece `Stateless`, recebendo todos os callbacks por parâmetro.
