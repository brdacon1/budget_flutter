import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_budget_row.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Item do modal: mesma linha do card do chat, no card da lista de orçamentos.
class ChatBudgetPickerTile extends StatelessWidget {
  final String name;
  final String date;
  final String status;
  final String value;
  final VoidCallback onTap;

  const ChatBudgetPickerTile({
    super.key,
    required this.name,
    required this.date,
    required this.status,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: secondaryColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: cardBorderColor),
      ),
      child: ChatBudgetRow(
        name: name,
        date: date,
        status: status,
        value: value,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
