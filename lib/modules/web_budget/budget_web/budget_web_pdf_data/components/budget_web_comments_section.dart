import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';

/// Seção colapsável "Comentários" exibida na aba "Meus dados".
///
/// Ao expandir, mostra a lista de observações/comentários do orçamento
/// (somente leitura) em forma de **tabela** (`DataTable`), no mesmo padrão
/// visual da seção de itens. Ao recolher, oculta a **lista inteira** — mesmo
/// comportamento da seção de itens. Reutiliza as observações já carregadas
/// pelo `BudgetWebBudgetViewModel` via `WebBudgetService.getObservations`.
///
/// Component **Stateless** puro — não acessa services nem Firebase.
class BudgetWebCommentsSection extends StatelessWidget {
  const BudgetWebCommentsSection({super.key, required this.observations});

  final List<ObservationPdf> observations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: false,
          initialElevation: 2,
          elevation: 4,
          shadowColor: Colors.black54,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.comment_outlined, color: whiteColor),
          ),
          title: Text(
            BudgetWebStrings.sectionComments,
            style: const TextStyle(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            if (observations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  BudgetWebStrings.commentsEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _CommentsTable(observations: observations),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Tabela de comentários com scroll horizontal, no padrão visual da
/// seção de itens (`_ItemsTable`). Cada linha exibe a data e o texto do
/// comentário.
class _CommentsTable extends StatelessWidget {
  const _CommentsTable({required this.observations});

  final List<ObservationPdf> observations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: defaultPadding,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(secondaryColor),
                dataRowColor: WidgetStateProperty.all(Colors.transparent),
                columns: [
                  DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        BudgetWebStrings.labelCommentDate,
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      BudgetWebStrings.labelCommentText,
                      style: const TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                rows: observations
                    .map(
                      (o) => DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(
                                _orEmpty(o.data),
                                style: const TextStyle(
                                  color: whiteColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _orEmpty(o.observacao),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: const TextStyle(
                                color: whiteColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _orEmpty(String? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty || s == 'null') return '-';
    return s;
  }
}
