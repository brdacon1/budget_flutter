import 'package:badges/badges.dart' as badges;
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_card.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/product_price_list_header.dart';
import 'package:oflite/shared/common/constants/colors.dart';

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
  const ProductPriceListView({super.key});

  @override
  State<ProductPriceListView> createState() => _ProductPriceListView();
}

class _ProductPriceListView extends State<ProductPriceListView> {
  late final ProductPriceListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPriceListViewModel();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
              checkBoxAppear: _viewModel.checkBoxAppear,
              onLongPress: _viewModel.onLongPress,
              onTap: () => _viewModel.openCreator(context, item: list[index]),
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
                onBack: () => Navigator.pop(context, true),
                onSearchChanged: (_) => _viewModel.onSearchChanged(),
              ),
              _buildList(list: list),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
