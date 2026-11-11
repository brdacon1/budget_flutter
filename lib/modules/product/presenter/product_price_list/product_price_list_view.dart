import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_card.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_list_header.dart';
import 'package:oflite/shared/common/constants/constants.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Barra inferior inspirada no print (estilo iFood): ocupa toda a largura do rodapé
  Widget _buildBottomAppBar() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        // Se estiver em modo seleção, usa o botão de finalizar seleção original
        if (_viewModel.selectionMode) {
          if (_viewModel.addItems.isEmpty) return const SizedBox.shrink();
          return BottomAppBar(
            color: const Color(0xFF1E1E2C),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (_viewModel.fromMenu || _viewModel.addItems.isEmpty) {
          return const SizedBox.shrink();
        }

        double totalPrice = 0.0;
        for (var p in _viewModel.addItems) {
          totalPrice += (p.preco ?? 0.0);
        }

        return BottomAppBar(
          color: const Color(0xFF161622),
          elevation: 10,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF00BFA5),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total dos itens',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${_viewModel.moneyConvert.convertFromDouble(totalPrice)} / ${_viewModel.addItems.length} ${_viewModel.addItems.length == 1 ? 'item' : 'itens'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _viewModel.openCartModal(context),
                    child: const Text(
                      'Ver Carrinho',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.selectionMode) return const SizedBox.shrink();

        if (_viewModel.deleteVisible) {
          return badges.Badge(
            badgeStyle: badges.BadgeStyle(
              badgeColor: const Color.fromARGB(255, 231, 15, 87),
              borderRadius: BorderRadius.circular(40),
            ),
            badgeContent: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Center(
                child: Text(
                  _viewModel.deleteItems.length.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'delete',
              onPressed: () => _viewModel.openDeleteModal(context),
              backgroundColor: buttonColor,
              elevation: 4,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.black,
              ),
              label: const Text(
                'Remover todos',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }

        return FloatingActionButton.extended(
          heroTag: 'adicionar_novo_item',
          onPressed: () => _viewModel.addNew(context),
          backgroundColor: buttonColor,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.black, size: 20),
          label: const Text(
            'Novo Item',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildList({required List<ProductPriceModel> list}) {
    return Expanded(
      child: RefreshIndicator(
        color: Colors.cyan[50],
        backgroundColor: bgColor,
        onRefresh: () async {
          await _viewModel.refresh();
          _viewModel.clearDeleteState();
        },
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            bottom: 160,
            left: 15,
            right: 15,
            top: 10,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return ProductPriceCard(
              item: list[index],
              moneyConvert: _viewModel.moneyConvert,
              fromMenu: _viewModel.fromMenu,
              checkBoxAppear: _viewModel.checkBoxAppear,
              checkBoxProductVisible:
                  _viewModel.checkBoxProductVisible || _viewModel.selectionMode,
              onLongPress:
                  _viewModel.selectionMode ? () {} : _viewModel.onLongPress,
              onTap:
                  _viewModel.selectionMode
                      ? () => _viewModel.toggleSelectProduct(context, index)
                      : () =>
                          _viewModel.openCreator(context, item: list[index]),
              onToggleSelectProduct:
                  () => _viewModel.toggleSelectProduct(context, index),
              onToggleDelete: () => _viewModel.toggleDeleteCheckbox(index),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final list = _viewModel.found;
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ProductPriceListHeader(
                searchController: _viewModel.searchController,
                title: _viewModel.selectionMode ? 'Selecionar produtos' : null,
                onBack: () => _viewModel.onBack(context),
                onSearchChanged: (_) => _viewModel.onSearchChanged(),
              ),
              _buildList(list: list),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }
}
