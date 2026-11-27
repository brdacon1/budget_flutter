import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';

/// Rodapé do modal: Excluir/Editar (leitura) ou Cancelar/Salvar (edição).
class BudgetCommentDetailActions extends StatelessWidget {
  const BudgetCommentDetailActions({
    super.key,
    required this.editing,
    required this.busy,
    required this.saving,
    required this.onDelete,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final bool editing;
  final bool busy;
  final bool saving;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final buttons =
        editing
            ? [
              ActionButton(
                icon: Icons.close_rounded,
                label: CommentStrings.cancelLabel,
                onPressed: busy ? () {} : onCancel,
              ),
              ActionButton(
                icon: Icons.check_rounded,
                label:
                    saving ? CommentStrings.saving : CommentStrings.saveLabel,
                backgroundColor: buttonColor.withValues(alpha: 0.25),
                onPressed: onSave,
              ),
            ]
            : [
              ActionButton(
                icon: Icons.delete_outline_rounded,
                label: CommentStrings.deleteLabel,
                backgroundColor: statusRejectedColor.withValues(alpha: 0.15),
                onPressed: onDelete,
              ),
              ActionButton(
                icon: Icons.edit_rounded,
                label: CommentStrings.editLabel,
                backgroundColor: buttonColor.withValues(alpha: 0.25),
                onPressed: onEdit,
              ),
            ];

    return Row(
      children: [
        Expanded(child: buttons[0]),
        const SizedBox(width: 8),
        Expanded(child: buttons[1]),
      ],
    );
  }
}
