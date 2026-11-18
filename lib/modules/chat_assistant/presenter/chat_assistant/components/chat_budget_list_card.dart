import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_ai_status_dot.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Lista de orçamentos devolvida pela IA. Cada linha abre o orçamento
/// (`open_budget|<id>`). Payload: `title`, `footer`, `items[{id, name,
/// value, status, date}]`.
class ChatBudgetListCard extends StatelessWidget {
  final Map<String, dynamic> payload;
  final void Function(String action)? onTap;

  const ChatBudgetListCard({super.key, required this.payload, this.onTap});

  @override
  Widget build(BuildContext context) {
    final items =
        (payload['items'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          payload['title'] as String? ?? '',
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items) _row(item),
        const SizedBox(height: 4),
        Text(
          payload['footer'] as String? ?? '',
          style: const TextStyle(color: mutedTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _row(Map<dynamic, dynamic> item) {
    final status = item['status'] as String? ?? '';
    return InkWell(
      onTap: onTap == null ? null : () => onTap!('open_budget|${item['id']}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ChatAiStatusDot(status: status),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: whiteColor),
                  ),
                  Text(
                    '${item['date'] ?? ''} · ${ChatBudgetStrings.budgetStatusLabel(status)}',
                    style: const TextStyle(color: mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              item['value'] as String? ?? '',
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
