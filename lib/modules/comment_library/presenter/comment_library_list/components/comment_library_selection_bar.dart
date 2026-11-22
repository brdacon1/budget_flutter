import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra do modo seleção: cancelar, "n selecionados" e selecionar todos.
class CommentLibrarySelectionBar extends StatelessWidget {
  const CommentLibrarySelectionBar({
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
            tooltip: CommentLibraryStrings.cancelSelection,
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: whiteColor),
          ),
          Text(
            CommentLibraryStrings.selectedCount(count),
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
              allSelected
                  ? CommentLibraryStrings.clearSelection
                  : CommentLibraryStrings.selectAll,
            ),
          ),
        ],
      ),
    );
  }
}
