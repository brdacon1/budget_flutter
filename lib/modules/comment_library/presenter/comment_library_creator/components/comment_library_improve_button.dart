import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// "✨ Melhorar com IA" → loading → "Desfazer" (até a próxima edição manual).
class CommentLibraryImproveButton extends StatelessWidget {
  const CommentLibraryImproveButton({
    super.key,
    required this.loading,
    required this.canUndo,
    required this.enabled,
    required this.onImprove,
    required this.onUndo,
    this.color = AppBottomModal.grayColor,
  });

  /// Cor do texto/ícone/borda — cinza no modal branco, clara no escuro.
  final Color color;

  final bool loading;
  final bool canUndo;
  final bool enabled;
  final VoidCallback onImprove;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final Widget icon =
        loading
            ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
            : Icon(
              canUndo ? Icons.undo_rounded : Icons.auto_awesome,
              size: 18,
            );
    final label =
        loading
            ? CommentLibraryStrings.improving
            : canUndo
            ? CommentLibraryStrings.undoButton
            : CommentLibraryStrings.improveButton;

    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed:
            loading || (!canUndo && !enabled)
                ? null
                : (canUndo ? onUndo : onImprove),
        icon: icon,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
