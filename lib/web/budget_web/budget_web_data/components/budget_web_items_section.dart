import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import '../../budget_web_items/components/budget_web_items_card.dart';
import '../../budget_web_items/components/budget_web_items_total_bar.dart';

/// Seção colapsável "Itens do orçamento" exibida na aba "Meus dados".
///
/// Ao expandir, mostra o campo de busca + os cards de item (cada um com seu
/// próprio expand/collapse, reutilizando `BudgetWebItemsCard`) + a barra de
/// totais. Ao recolher, oculta a **lista inteira** — comportamento pedido na
/// spec: "ocultar ou mostrar a lista toda".
///
/// Component **Stateless** puro — recebe a lista já filtrada, o controller
/// de busca (de dono da View) e callbacks. Não acessa services nem Firebase.
class BudgetWebItemsSection extends StatelessWidget {
  const BudgetWebItemsSection({
    super.key,
    required this.items,
    required this.moneyConvert,
    required this.totalProducts,
    required this.totalServices,
    required this.totalBudget,
    required this.searchController,
    required this.onSearchChanged,
  });

  final List<ItemsBudget> items;
  final ConvertCoin moneyConvert;
  final double totalProducts;
  final double totalServices;
  final double totalBudget;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.list_alt_outlined, color: whiteColor),
          ),
          title: Text(
            BudgetWebStrings.sectionItems,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CupertinoSearchTextField(
                  placeholder: BudgetWebStrings.itemsSearchHint,
                  style: const TextStyle(color: whiteColor, fontSize: 14),
                  backgroundColor: Colors.transparent,
                  itemColor: whiteColor,
                  controller: searchController,
                  onChanged: (_) => onSearchChanged(),
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  BudgetWebStrings.itemsEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )
            else
              ...items.map(
                (item) => BudgetWebItemsCard(
                  item: item,
                  moneyConvert: moneyConvert,
                ),
              ),
            const SizedBox(height: 8),
            BudgetWebItemsTotalBar(
              moneyConvert: moneyConvert,
              totalProducts: totalProducts,
              totalServices: totalServices,
              totalBudget: totalBudget,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
