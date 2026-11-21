import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_ai_status_dot.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Linha de orçamento (status, cliente, data · status, valor e seta).
/// Usada no card da IA e no modal de seleção de orçamento.
class ChatBudgetRow extends StatelessWidget {
  final String name;
  final String date;
  final String status;
  final String value;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const ChatBudgetRow({
    super.key,
    required this.name,
    required this.date,
    required this.status,
    required this.value,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            ChatAiStatusDot(status: status),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: whiteColor),
                  ),
                  Text(
                    '$date · ${ChatAssistantStrings.budgetStatusLabel(status)}',
                    style: const TextStyle(color: mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.chevron_right, color: mutedTextColor, size: 18),
          ],
        ),
      ),
    );
  }
}
