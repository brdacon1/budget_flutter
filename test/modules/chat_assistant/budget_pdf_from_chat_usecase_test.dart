import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/build_budget_final_actions_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/generate_budget_pdf_from_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeAccess implements GetAccessStatusUseCase {
  _FakeAccess({required this.hasFullAccess});
  @override
  final bool hasFullAccess;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeChatRepo extends ChangeNotifier implements ChatBudgetRepository {
  _FakeChatRepo(this.draftBudget);
  @override
  final CustomerInfo? draftBudget;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeBudgetRepo extends ChangeNotifier implements BudgetRepository {
  @override
  ValueNotifier<CustomerInfo?> selectBudget = ValueNotifier(null);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuildBudgetFinalActionsUsecase', () {
    test('acesso total: copiar link + gerar PDF', () {
      final actions =
          BuildBudgetFinalActionsUsecase(_FakeAccess(hasFullAccess: true))();
      expect(actions, [
        ChatAssistantStrings.copyLinkLabel,
        ChatAssistantStrings.generatePdfLabel,
      ]);
    });

    test('expirado: só gerar PDF', () {
      final actions =
          BuildBudgetFinalActionsUsecase(_FakeAccess(hasFullAccess: false))();
      expect(actions, [ChatAssistantStrings.generatePdfLabel]);
    });
  });

  group('GenerateBudgetPdfFromChatUsecase', () {
    test('seleciona o orçamento sem anúncio', () async {
      final budgetRepo = _FakeBudgetRepo();
      final draft = CustomerInfo(id: 'abc');
      final r =
          await GenerateBudgetPdfFromChatUsecase(
            _FakeChatRepo(draft),
            budgetRepo,
          )();
      expect(r, isA<Ok<void>>());
      expect(budgetRepo.selectBudget.value, same(draft));
    });

    test('sem rascunho retorna erro', () async {
      final r =
          await GenerateBudgetPdfFromChatUsecase(
            _FakeChatRepo(null),
            _FakeBudgetRepo(),
          )();
      expect(r, isA<Error<void>>());
    });
  });
}
