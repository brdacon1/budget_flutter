import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/product/product_price_creator/presenter/product_price_creator_view.dart';
import 'package:oflite/modules/product/product_price_list/presenter/product_price_list_view.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'components/budget_list_items_card.dart';
import 'components/modals/budget_list_items_delete_bottom_modal_widget.dart';
import 'components/budget_list_items_total_bar.dart';
import 'budget_list_items_view_model.dart';

class BudgetListItemsView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetListItemsView({Key? key, required this.item}) : super(key: key);

  @override
  State<BudgetListItemsView> createState() => _BudgetListItemsView();
}

class _BudgetListItemsView extends State<BudgetListItemsView> {
  late final BudgetListItemsViewModel _viewModel;
  var displayAlert = DisplayAlert();

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetListItemsViewModel(item: widget.item);
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
          deleteItens: _viewModel.deleteItens,
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
                SizedBox(
                  height: he * 0.02,
                ),
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
                      margin: EdgeInsets.only(left: we * 0.028),
                      child: const Icon(
                        Icons.arrow_back_outlined,
                        color: Colors.white,
                        size: 35.0,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: he * 0.02,
              ),
              FadeAnimationWidget(
                delay: 1,
                child: Container(
                  alignment: Alignment.topLeft,
                  margin: EdgeInsets.only(left: we * 0.035),
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
              ),
              SizedBox(
                height: he * 0.02,
              ),
              FadeAnimationWidget(
                delay: 1,
                child: Container(
                  height: 50.0,
                  margin:
                      const EdgeInsets.only(right: 15.0, left: 15.0, bottom: 25),
                  child: CupertinoSearchTextField(
                    placeholder: "Digite a descrição do item...",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0),
                    backgroundColor: Colors.white12,
                    itemColor: Colors.white,
                    controller: searchController,
                    onChanged: _viewModel.onSearchTextChanged,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.cyan[50],
                  backgroundColor: bgColor,
                  onRefresh: () async {
                    await _viewModel.getListItens();
                    _viewModel.clearDeleteItens();
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.only(bottom: 100, left: 15, right: 15, top: 3),
                    itemCount: _viewModel.getFilteredData().length,
                    itemBuilder: (context, index) {
                      return BudgetListItemsCard(
                        item: _viewModel.getFilteredData()[index],
                        moneyConvert: _viewModel.moneyConvert,
                        onDelete: () => _viewModel.toggleDeleteItem(index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
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
                  child: FloatingActionButton(
                    heroTag: "delete",
                    onPressed: _dialogDeleteBuilder,
                    backgroundColor: buttonColor,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(height: he * 0.02),
              FloatingActionButton(
                heroTag: "adicionar",
                onPressed: () async {
                  if (await _viewModel.getProductCount() > 0) {
                    final value = await displayAlert.listNotification(context);
                    if (value == "Criar novo item") {
                      budget.fromListItem = true;
                      await showProductPriceCreatorBottomModal(
                        context,
                        item: ProductPriceModel.fromItemsBudget(
                            _viewModel.novo),
                      );
                    } else if (value == "Selecionar da lista de preço") {
                      budget.fromListItem = false;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProductPriceListView(
                                item: widget.item, fromMenu: false)),
                      );
                    }
                    budget.fromListItem = false;
                    await _viewModel.getListItens();
                  } else {
                    budget.fromListItem = true;
                    await showProductPriceCreatorBottomModal(
                      context,
                      item: ProductPriceModel.fromItemsBudget(
                          _viewModel.novo),
                    );
                    budget.fromListItem = false;
                    await _viewModel.getListItens();
                  }
                },
                backgroundColor: buttonColor,
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return BudgetListItemsTotalBar(viewModel: _viewModel);
        },
      ),
    );
  }
}
