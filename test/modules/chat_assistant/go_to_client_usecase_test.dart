import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_client_address_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_go_to_client_prompt_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeChatRepo extends ChangeNotifier implements ChatBudgetRepository {
  final sent = <ChatMessageEntity>[];

  @override
  Future<Result<void>> sendMessage(ChatMessageEntity message) async {
    sent.add(message);
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prompt abre o modal e tem "Voltar ao menu"', () async {
    final repo = _FakeChatRepo();
    final nav = await ShowGoToClientPromptUsecase(repo)();
    final msg = repo.sent.single;
    expect(nav, ShowGoToClientPromptUsecase.selectBudgetAction);
    expect(msg.content, ChatAssistantStrings.goToClientPrompt);
    expect(
      msg.payload!['action'],
      ShowGoToClientPromptUsecase.selectBudgetAction,
    );
    expect(msg.payload!['backLabel'], ChatAssistantStrings.menuBackLabel);
  });

  test('com endereço: texto traz o endereço e botão abre o mapa', () async {
    final repo = _FakeChatRepo();
    final budget = CustomerInfo(
      id: '123',
      customerName: 'Ana',
      street: 'Rua A, 10',
      city: 'Recife',
    );
    await ShowClientAddressUsecase(repo)(budget);
    final msg = repo.sent.single;
    expect(msg.content, contains('📍'));
    expect(msg.content, contains('Rua A, 10, Recife'));
    expect(
      msg.payload!['action'],
      '${ShowClientAddressUsecase.openMapAction}123',
    );
    expect(msg.payload!['label'], ChatAssistantStrings.goToClientOpenMapLabel);
    expect(msg.payload!['backLabel'], ChatAssistantStrings.menuBackLabel);
  });

  test('sem endereço: avisa e oferece escolher outro orçamento', () async {
    final repo = _FakeChatRepo();
    final budget = CustomerInfo(id: '123', customerName: 'Ana', city: 'Recife');
    await ShowClientAddressUsecase(repo)(budget);
    final msg = repo.sent.single;
    expect(msg.content, ChatAssistantStrings.goToClientNoAddress('Ana'));
    expect(
      msg.payload!['action'],
      ShowGoToClientPromptUsecase.selectBudgetAction,
    );
    expect(msg.payload!['backLabel'], ChatAssistantStrings.menuBackLabel);
  });
}
