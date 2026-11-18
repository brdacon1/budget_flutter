import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/resolve_ai_failure_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const resolve = ResolveAiFailureUsecase();

  test('1ª falha só avisa; continua no modo IA', () {
    final d = resolve(Exception('timeout'), consecutiveFailures: 1);
    expect(d.fallbackToStandard, isFalse);
    expect(d.message, ChatBudgetStrings.aiFallback);
  });

  test('falhas seguidas → modo padrão (igual free)', () {
    final d = resolve(
      Exception('timeout'),
      consecutiveFailures: ResolveAiFailureUsecase.maxConsecutiveFailures,
    );
    expect(d.fallbackToStandard, isTrue);
    expect(d.message, ChatBudgetStrings.aiUnavailable);
  });

  test('limite diário → modo padrão já na 1ª vez', () {
    final d = resolve(const AiDailyLimitException(), consecutiveFailures: 1);
    expect(d.fallbackToStandard, isTrue);
    expect(d.message, ChatBudgetStrings.aiDailyLimit);
  });
}
