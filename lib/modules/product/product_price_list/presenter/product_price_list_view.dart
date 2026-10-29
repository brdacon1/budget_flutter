import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/modules/product/product_price_list/presenter/components/product_price_card.dart';
import 'package:oflite/modules/product/product_price_list/presenter/components/product_price_list_header.dart';

import 'product_price_list_view_model.dart';

/// Tela de **lista de preço** (produtos/serviços).
///
/// `StatefulWidget` que cria o [ProductPriceListViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + lista + FABs) e delega as
/// ações (carregar, buscar, abrir carrinho, excluir, criar/editar, voltar)
/// ao ViewModel. Os blocos visuais repetidos vivem em `components/`
/// ([ProductPriceListHeader], [ProductPriceCard]).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Componentes recebem dados + callbacks, nunca o VM inteiro.
/// - `BuildContext` recebido por parâmetro nos métodos do VM (não guardado).
/// - Nenhum texto visível ao usuário como literal — todos via
///   `ProductStrings`.
class ProductPriceListView extends StatefulWidget {
  final CustomerInfo? item;
  final bool? fromMenu;
  final bool selectionMode;

  /// Quando [selectionMode] é true, a tela funciona como picker multi-seleção
  /// e retorna [List<ItemsBudget>] via Navigator.pop.
  const ProductPriceListView({
    super.key,
    this.item,
    this.fromMenu,
    this.selectionMode = false,
  });

  @override
  State<ProductPriceListView> createState() => _ProductPriceListView();
}

class _ProductPriceListView extends State<ProductPriceListView> {
  late final ProductPriceListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPriceListViewModel(
      item: widget.item,
      fromMenu: widget.fromMenu ?? false,
      selectionMode: widget.selectionMode,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final found = _viewModel.found;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ProductPriceListHeader(
                searchController: _viewModel.searchController,
                title: _viewModel.selectionMode ? 'Selecionar produtos' : null,
                onBack: () => _viewModel.onBack(context),
                onSearchChanged: (_) => _viewModel.onSearchChanged(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.cyan[50],
                  backgroundColor: bgColor,
                  onRefresh: _viewModel.refresh,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                        bottom: 160, left: 15, right: 15, top: 10),
                    itemCount: found.length,
                    itemBuilder: (context, index) {
                      return ProductPriceCard(
                        item: found[index],
                        moneyConvert: _viewModel.moneyConvert,
                        fromMenu: _viewModel.fromMenu,
                        checkBoxAppear: _viewModel.checkBoxAppear,
                        checkBoxProductVisible: _viewModel.checkBoxProductVisible || _viewModel.selectionMode,
                        onLongPress: _viewModel.selectionMode ? () {} : _viewModel.onLongPress,
                        onTap: _viewModel.selectionMode
                            ? () => _viewModel.toggleSelectProduct(context, index)
                            : () => _viewModel.openCreator(context, item: found[index]),
                        onToggleSelectProduct: () =>
                            _viewModel.toggleSelectProduct(context, index),
                        onToggleDelete: () =>
                            _viewModel.toggleDeleteCheckbox(index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final he = MediaQuery.of(context).size.height;

          // Em modo seleção escondemos os FABs padrão e usamos BottomAppBar
          if (_viewModel.selectionMode) return const SizedBox.shrink();

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              // Carrinho de produtos (adicionar ao orçamento).
              Visibility(
                visible: !_viewModel.fromMenu && !_viewModel.deleteVisible,
                child: _CartBadge(
                  count: _viewModel.addItems.length,
                  heroTag: 'car',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => _viewModel.openCartModal(context),
                ),
              ),
              // Exclusão de produtos.
              Visibility(
                visible: _viewModel.deleteVisible,
                child: _CartBadge(
                  count: _viewModel.deleteItems.length,
                  heroTag: 'delete',
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _viewModel.openDeleteModal(context),
                ),
              ),
              SizedBox(height: he * 0.02),
              FloatingActionButton(
                heroTag: 'adicionar',
                onPressed: () => _viewModel.addNew(context),
                backgroundColor: buttonColor,
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (!_viewModel.selectionMode || _viewModel.addItems.isEmpty) {
            return const SizedBox.shrink();
          }
          return BottomAppBar(
            color: const Color(0xFF1E1E2C),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => _viewModel.finalizeSelection(context),
                  child: Text(
                    'Finalizar seleção (${_viewModel.addItems.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// FAB com badge de contagem (carrinho / exclusão).
class _CartBadge extends StatelessWidget {
  const _CartBadge({
    required this.count,
    required this.heroTag,
    required this.icon,
    required this.onPressed,
  });

  final int count;
  final String heroTag;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
      badgeStyle: badges.BadgeStyle(
        badgeColor: const Color.fromARGB(255, 231, 15, 87),
        borderRadius: BorderRadius.circular(40),
      ),
      badgeContent: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Center(
          child: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: buttonColor,
        child: Icon(icon, color: Colors.black),
      ),
    );
  }
}
