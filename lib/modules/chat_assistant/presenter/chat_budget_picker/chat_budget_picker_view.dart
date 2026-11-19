import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/chat_budget_picker_view_model.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/components/chat_budget_picker_header.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_budget_picker/components/chat_budget_picker_tile.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Modal (bottom sheet) para escolher um orçamento no chat.
///
/// Ocupa 50% da tela; 80% enquanto a busca está em foco. Fecha devolvendo o
/// id do orçamento tocado, ou `null` se o usuário sair sem escolher.
class ChatBudgetPickerView extends StatefulWidget {
  const ChatBudgetPickerView({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: transparentColor,
      builder: (_) => const ChatBudgetPickerView(),
    );
  }

  @override
  State<ChatBudgetPickerView> createState() => _ChatBudgetPickerViewState();
}

class _ChatBudgetPickerViewState extends State<ChatBudgetPickerView> {
  final _vm = getIt<ChatBudgetPickerViewModel>();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    _vm.init();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final factor = _searchFocus.hasFocus ? 0.8 : 0.6;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: media.size.height * factor,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: ListenableBuilder(
          listenable: _vm,
          builder:
              (context, _) => Column(
                children: [
                  ChatBudgetPickerHeader(
                    searchFocus: _searchFocus,
                    status: _vm.status,
                    onSearch: _vm.search,
                    onStatus: _vm.selectStatus,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildList()),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_vm.isLoading && _vm.budgets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: loadingIndicatorColor),
      );
    }
    if (_vm.budgets.isEmpty) {
      return Center(
        child: Text(
          ChatBudgetStrings.budgetPickerEmpty,
          style: const TextStyle(color: mutedTextColor),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _vm.budgets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = _vm.budgets[i];
        return ChatBudgetPickerTile(
          name: b.customerName ?? '',
          date: b.data ?? '',
          status: b.status ?? '',
          value: _vm.formatValue(b),
          onTap: () => Navigator.of(context).pop(b.id),
        );
      },
    );
  }
}
