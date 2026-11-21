import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/reset_chat_to_menu_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_reports_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeChatRepo extends ChangeNotifier implements ChatBudgetRepository {
  final sent = <ChatMessageEntity>[];
  int clears = 0;

  @override
  Future<Result<void>> sendMessage(ChatMessageEntity message) async {
    sent.add(message);
    return const Result.ok(null);
  }

  @override
  void clearSession() => clears++;

  @override
  void setCurrentFlowStep(String? step) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<String> _labels(ChatMessageEntity m) => [
  for (final o in m.payload!['options'] as List) o['label'] as String,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('menu do modo IA tem "Relatórios" (5) e "Encontrar orçamentos" (6)', () async {
    final repo = _FakeChatRepo();
    await ResetChatToMenuUsecase(repo)(withReports: true);
    final options = repo.sent.single.payload!['options'] as List;
    expect(options[options.length - 2], {
      'label': ChatAssistantStrings.reportsOptionLabel,
      'value': '5',
    });
    expect(options.last, {
      'label': ChatAssistantStrings.findBudgetOptionLabel,
      'value': '6',
    });
  });

  test(
    'menu free (ou modo padrão de segurança) não tem "Relatórios"',
    () async {
      final repo = _FakeChatRepo();
      await ResetChatToMenuUsecase(repo)(clearSession: false);
      expect(
        _labels(repo.sent.single),
        isNot(contains(ChatAssistantStrings.reportsOptionLabel)),
      );
      expect(repo.clears, 0);
    },
  );

  test('"Relatórios" pede a pergunta com exemplo e fica no menu', () async {
    final repo = _FakeChatRepo();
    final step = await ShowReportsPromptUsecase(repo)();
    final msg = repo.sent.single;
    expect(step, 'mainMenu');
    expect(msg.content, contains(ChatAssistantStrings.reportsPrompt));
    expect(msg.content, contains(ChatAssistantStrings.reportsExample));
    expect(msg.payload!['highlight'], ChatAssistantStrings.reportsExample);
  });
}
