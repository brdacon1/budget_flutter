import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'components/budget_web_items_card.dart';
import 'components/budget_web_items_total_bar.dart';
import 'components/modals/budget_web_approval_modal_widget.dart';

/// Tab "Itens" do orçamento Web.
///
/// Exibe **somente visualização** dos itens (o cliente não adiciona nem
/// remove). No lugar do botão "Inserir mais itens" do mobile, mostra
/// "Aprovar orçamento", exclusivo da versão Web.
class BudgetWebItemsView extends StatefulWidget {
  const BudgetWebItemsView({
    super.key,
    required this.items,
    required this.moneyConvert,
    required this.totalProducts,
    required this.totalServices,
    required this.totalBudget,
    required this.onApprove,
  });

  final List<ItemsBudget> items;
  final ConvertCoin moneyConvert;
  final double totalProducts;
  final double totalServices;
  final double totalBudget;

  /// Callback de aprovação/reprovação (gravado pelo ViewModel do orçamento).
  final ValueChanged<String> onApprove;

  @override
  State<BudgetWebItemsView> createState() => _BudgetWebItemsViewState();
}

class _BudgetWebItemsViewState extends State<BudgetWebItemsView> {
  final TextEditingController _searchController = TextEditingController();

  List<ItemsBudget> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((i) => (i.DESCRICAO ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: <Widget>[
          SizedBox(height: he * 0.05),
          FadeAnimationWidget(
            delay: 1,
            child: Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: we * 0.04),
              child: Text(
                BudgetWebStrings.itemsTitle,
                style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: he * 0.02),
          FadeAnimationWidget(
            delay: 1,
            child: Container(
              height: 50.0,
              margin: const EdgeInsets.only(
                  right: 15.0, left: 15.0, bottom: 16),
              child: CupertinoSearchTextField(
                placeholder: BudgetWebStrings.itemsSearchHint,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0),
                backgroundColor: Colors.white12,
                itemColor: Colors.white,
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Expanded(
            child: widget.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum item neste orçamento.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                        bottom: 100, left: 15, right: 15, top: 3),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => BudgetWebItemsCard(
                      item: _filtered[index],
                      moneyConvert: widget.moneyConvert,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: we * 0.7,
        height: 52,
        child: FloatingActionButton.extended(
          heroTag: 'approve',
          backgroundColor: buttonColor,
          onPressed: () async {
            await showBudgetWebApprovalModal(
              context,
              onSelect: (status) => widget.onApprove(status),
            );
          },
          icon: const Icon(Icons.task_alt, color: bgColor),
          label: Text(
            BudgetWebStrings.approveButton,
            style: GoogleFonts.heebo(
              color: bgColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BudgetWebItemsTotalBar(
        moneyConvert: widget.moneyConvert,
        totalProducts: widget.totalProducts,
        totalServices: widget.totalServices,
        totalBudget: widget.totalBudget,
      ),
    );
  }
}
