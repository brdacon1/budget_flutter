import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view.dart';
import 'package:oflite/modules/product/presenter/product_price_list/product_price_list_view.dart';
import 'package:oflite/shared/common/constants/constants.dart';

import 'budget_list_items_view_model.dart';
import 'components/budget_list_items_card.dart';
import 'components/budget_list_items_total_bar.dart';
import 'components/modals/budget_list_items_delete_bottom_modal_widget.dart';

class BudgetListItemsView extends StatefulWidget {
  final CustomerInfo item;

  const BudgetListItemsView({super.key, required this.item});

  @override
  State<BudgetListItemsView> createState() => _BudgetListItemsView();
}

class _BudgetListItemsView extends State<BudgetListItemsView> {
  late final BudgetListItemsViewModel _viewModel;
  var displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetListItemsViewModel(item: widget.item);
    getIt<BudgetRepository>().selectBudget.value = widget.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.getListItens();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _dialogDeleteBuilder() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BudgetListItemsDeleteBottomModalWidget(
          deleteItems: _viewModel.deleteItens,
          moneyConvert: _viewModel.moneyConvert,
          onRemove: (item) => _viewModel.removeDeleteItem(item),
          onConfirm: () async {
            await _viewModel.deleteData();
            _viewModel.clearDeleteItens();
          },
        );
      },
    ).then((_) async {
      if (_viewModel.deleteItens.isEmpty) {
        await _viewModel.getListItens();
      }
    });
  }

  Future<void> _showProductPriceCreatorBottomModal() async {
    await showProductPriceCreatorBottomModal(
      context,
      item: ProductPriceModel.fromItemsBudget(_viewModel.newItemsBudget),
      fromListItem: true,
    ).then((value) async {
      await _viewModel.getListItens();
    });
  }

  Future<void> _openPriceList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ProductPriceListView(item: widget.item, fromMenu: false),
      ),
    ).then((value) async {
      await _viewModel.getListItens();
    });
  }

  Widget _buildHeader({required double height, required double width}) {
    return Column(
      children: [
        SizedBox(height: height * 0.02),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.pop(context, true);
              },
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: width * 0.028),
                child: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: height * 0.02),
        Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsets.only(left: width * 0.035),
          child: Text(
            "Itens orçamentos",
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: height * 0.02),
      ],
    );
  }

  Widget _buildList() {
    final filteredItems = _viewModel.getFilteredData();

    return Expanded(
      child: RefreshIndicator(
        color: Colors.cyan[50],
        backgroundColor: bgColor,
        onRefresh: () async {
          await _viewModel.getListItens();
          _viewModel.clearDeleteItens();
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 100,
            left: 15,
            right: 15,
            top: 3,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            return BudgetListItemsCard(
              item: filteredItems[index],
              moneyConvert: _viewModel.moneyConvert,
              onDelete: () => _viewModel.toggleDeleteItem(index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50.0,
      margin: const EdgeInsets.only(right: 15.0, left: 15.0, bottom: 25),
      child: CupertinoSearchTextField(
        placeholder: "Digite a descrição do item...",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
        backgroundColor: Colors.white12,
        itemColor: Colors.white,
        controller: searchController,
        onChanged: _viewModel.onSearchTextChanged,
      ),
    );
  }

  Widget _buildFloatingActionButton({required double height}) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Visibility(
              visible: _viewModel.deleteVisible,
              child: badges.Badge(
                badgeStyle: badges.BadgeStyle(
                  badgeColor: const Color.fromARGB(255, 231, 15, 87),
                  borderRadius: BorderRadius.circular(40),
                ),
                badgeContent: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Center(
                    child: Text(
                      _viewModel.deleteItens.length.toString(),
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
                  heroTag: "delete",
                  onPressed: _dialogDeleteBuilder,
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
              ),
            ),
            Visibility(
              visible: !_viewModel.deleteVisible,
              child: FloatingActionButton.extended(
                heroTag: "adicionar",
                onPressed: () async {
                  if (await _viewModel.getProductCount() > 0) {
                    if (!mounted) return;
                    final value = await displayAlert.listNotification(context);
                    if (value == "Criar novo item") {
                      _showProductPriceCreatorBottomModal();
                    } else if (value == "Selecionar da lista de preço") {
                      _openPriceList();
                    }
                  } else {
                    _showProductPriceCreatorBottomModal();
                  }
                },
                backgroundColor: buttonColor,
                elevation: 4,
                icon: const Icon(Icons.add, color: Colors.black, size: 20),
                label: const Text(
                  'Adicionar item',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final bottomInset = MediaQuery.of(context).viewPadding.bottom;
        return Container(
          color: buttonColor,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: BudgetListItemsTotalBar(viewModel: _viewModel),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                _buildHeader(height: he, width: we),
                _buildSearchBar(),
                _buildList(),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(height: he),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
