import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra do modo seleção: cancelar, "n selecionados" e selecionar todos.
class BudgetCommentSelectionBar extends StatelessWidget {
  const BudgetCommentSelectionBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.onCancel,
    required this.onToggleAll,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onCancel;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: CommentStrings.cancelSelection,
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: whiteColor),
          ),
          Text(
            CommentStrings.selectedCount(count),
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onToggleAll,
            style: TextButton.styleFrom(foregroundColor: buttonColor),
            child: Text(
              allSelected ? CommentStrings.clearAll : CommentStrings.selectAll,
            ),
          ),
        ],
      ),
    );
  }
}
