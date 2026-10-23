import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';

/// Seção colapsável "Itens do orçamento" exibida na aba "Meus dados".
///
/// Ao expandir, mostra o campo de busca e a lista de itens em forma de
/// **tabela** (`DataTable`) com scroll horizontal — mesma abordagem visual
/// usada pelo dashboard do app (`RecentFiles`), em vez dos cards antigos
/// cheios de `Divider` entre cada informação do item. Assim o cliente
/// consegue ver todos os dados de cada item de uma vez, rolando a tabela
///横向mente quando a tela é estreita.
///
/// A barra de totais é fixa no rodapé da aba (fora desta seção).
///
/// Component **Stateless** puro — recebe a lista já filtrada, o controller
/// de busca (de dono da View) e callbacks. Não acessa services nem Firebase.
class BudgetWebItemsSection extends StatelessWidget {
  const BudgetWebItemsSection({
    super.key,
    required this.items,
    required this.moneyConvert,
    required this.searchController,
    required this.onSearchChanged,
  });

  final List<ItemsBudget> items;
  final ConvertCoin moneyConvert;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          initialElevation: 2,
          elevation: 4,
          shadowColor: Colors.black54,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _ItemsTable(
                  items: items,
                  moneyConvert: moneyConvert,
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Tabela de itens com scroll horizontal, no padrão visual do dashboard
/// (`RecentFiles`). Sem dividers entre cada informação do item — cada item
/// é uma linha limpa da `DataTable`.
class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items, required this.moneyConvert});

  final List<ItemsBudget> items;
  final ConvertCoin moneyConvert;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: defaultPadding,
          horizontalMargin: 12,
          headingRowColor: WidgetStateProperty.all(secondaryColor),
          dataRowColor: WidgetStateProperty.all(Colors.transparent),
          columns: const [
            DataColumn(
              label: Text(
                'Descrição',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Categoria',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Qtd',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Unidade',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Preço',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Total',
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          rows: items
              .map(
                (item) => DataRow(
                  cells: [
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Tooltip(
                          message: item.DESCRICAO ?? '',
                          child: Text(
                            item.DESCRICAO ?? '-',
                            softWrap: true,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: whiteColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      item.CATEGORIA ?? '-',
                      style: const TextStyle(color: whiteColor, fontSize: 12),
                    )),
                    DataCell(Text(
                      '${item.QTD ?? 0}',
                      style: const TextStyle(color: whiteColor, fontSize: 12),
                    )),
                    DataCell(Text(
                      item.MEDIDA ?? '-',
                      style: const TextStyle(color: whiteColor, fontSize: 12),
                    )),
                    DataCell(Text(
                      moneyConvert.convertFromDouble(item.PRECO ?? 0),
                      style: const TextStyle(color: whiteColor, fontSize: 12),
                    )),
                    DataCell(Text(
                      moneyConvert.convertFromDouble(item.TOTAL ?? 0),
                      style: const TextStyle(
                        color: buttonColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}