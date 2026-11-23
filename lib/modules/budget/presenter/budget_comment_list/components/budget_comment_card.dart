import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card do comentário do orçamento no visual dos cards de lista (lista de
/// preço): ícone, texto (2 linhas), data e check circular de remoção.
/// `onTap` abre o detalhe (ou alterna seleção no modo remoção).
class BudgetCommentCard extends StatelessWidget {
  const BudgetCommentCard({
    super.key,
    required this.comment,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final ObservationBudget comment;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: selected ? buttonColor.withValues(alpha: 0.08) : secondaryColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: selected ? buttonColor : priceCardBorderColor,
          width: 1.2,
        ),
      ),
      child: Material(
        color: transparentColor,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: bgColor,
                  child: Icon(Icons.comment, color: whiteColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.observacao ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CommentStrings.dateLabel(comment.data ?? ''),
                        style: const TextStyle(
                          color: priceTextColor,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                InkResponse(
                  onTap: onToggleSelect,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? buttonColor : transparentColor,
                        border: Border.all(
                          color: selected ? buttonColor : priceTextColor,
                          width: 2.2,
                        ),
                      ),
                      child:
                          selected
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: bgColor,
                              )
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
