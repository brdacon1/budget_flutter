import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/models/observation_pdf.dart';

/// Seção colapsável "Comentários" exibida na aba "Meus dados".
///
/// Ao expandir, mostra a lista de observações/comentários do orçamento
/// (somente leitura). Ao recolher, oculta a **lista inteira** — mesmo
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: false,
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
              ...observations.map((o) => _CommentRow(observation: o)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.observation});

  final ObservationPdf observation;

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: he * 0.012),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${BudgetWebStrings.labelCommentDate}: ${_orEmpty(observation.data)}',
            style: GoogleFonts.heebo(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _orEmpty(observation.observacao),
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _orEmpty(String? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty || s == 'null') return '-';
    return s;
  }
}
