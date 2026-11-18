import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_ai_status_dot.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Resumo do mês devolvido pela IA. Os números vêm do usecase, nunca do
/// modelo. Payload: `title`, `totalLabel`, `total`, `count`,
/// `rows[{status, label, count, total}]`.
class ChatMonthSummaryCard extends StatelessWidget {
  final Map<String, dynamic> payload;

  const ChatMonthSummaryCard({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final rows =
        (payload['rows'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
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
        Text(
          payload['totalLabel'] as String? ?? '',
          style: const TextStyle(color: mutedTextColor, fontSize: 12),
        ),
        Text(
          '${payload['total'] ?? ''}  (${payload['count'] ?? 0})',
          style: const TextStyle(
            color: whiteColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                ChatAiStatusDot(status: row['status'] as String? ?? ''),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${row['label']} (${row['count']})',
                    style: const TextStyle(color: whiteColor),
                  ),
                ),
                Text(
                  row['total'] as String? ?? '',
                  style: const TextStyle(color: whiteColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
