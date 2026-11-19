import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cabeçalho do modal: alça, título, busca por cliente e filtro de status.
class ChatBudgetPickerHeader extends StatelessWidget {
  final FocusNode searchFocus;
  final BudgetStatus? status;
  final ValueChanged<String> onSearch;
  final ValueChanged<BudgetStatus?> onStatus;

  const ChatBudgetPickerHeader({
    super.key,
    required this.searchFocus,
    required this.status,
    required this.onSearch,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 14),
        Text(
          ChatBudgetStrings.budgetPickerTitle,
          style: const TextStyle(
            color: whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          focusNode: searchFocus,
          onChanged: onSearch,
          style: const TextStyle(color: whiteColor),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: ChatBudgetStrings.budgetPickerSearchHint,
            hintStyle: const TextStyle(color: mutedTextColor),
            prefixIcon: const Icon(Icons.search, color: mutedTextColor),
            filled: true,
            fillColor: secondaryColor,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: buttonColor),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(ChatBudgetStrings.budgetPickerAllStatus, null),
              for (final s in BudgetStatus.values)
                _chip(ChatBudgetStrings.budgetStatusLabel(s.value), s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, BudgetStatus? value) {
    final selected = status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onStatus(value),
        backgroundColor: secondaryColor,
        selectedColor: buttonColor,
        side: BorderSide(color: selected ? buttonColor : cardBorderColor),
        labelStyle: TextStyle(
          color: selected ? blackColor : whiteColor,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
