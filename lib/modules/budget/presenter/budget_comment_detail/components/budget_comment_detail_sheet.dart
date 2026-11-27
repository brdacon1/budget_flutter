import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Casca visual do modal de comentário: handle, título + data, divisor,
/// conteúdo rolável e rodapé de ações. Altura máxima de 80% da área visível.
class BudgetCommentDetailSheet extends StatelessWidget {
  const BudgetCommentDetailSheet({
    super.key,
    required this.date,
    required this.body,
    required this.actions,
  });

  final String date;
  final Widget body;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = (mq.size.height - mq.viewInsets.bottom) * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: sheetHandleColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                CommentStrings.title,
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                CommentStrings.dateLabel(date),
                style: const TextStyle(color: mutedTextColor, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(color: cardBorderColor, height: 1),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: body,
                ),
              ),
              const SizedBox(height: 16),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
