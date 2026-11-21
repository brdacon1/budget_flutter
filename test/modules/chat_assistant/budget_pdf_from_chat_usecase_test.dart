import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_budget_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/build_budget_final_actions_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/generate_budget_pdf_from_chat_usecase.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeAds implements AdsRepository {
  _FakeAds({required this.shouldShowAds});
  @override
  final bool shouldShowAds;
  int waited = 0;
  @override
  Future<void> showInterstitialAndWait() async => waited++;
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
    test('assinante: copiar link + gerar PDF', () {
      final actions =
          BuildBudgetFinalActionsUsecase(_FakeAds(shouldShowAds: false))();
      expect(actions, [
        ChatAssistantStrings.copyLinkLabel,
        ChatAssistantStrings.generatePdfLabel,
      ]);
    });

    test('não assinante: só gerar PDF', () {
      final actions =
          BuildBudgetFinalActionsUsecase(_FakeAds(shouldShowAds: true))();
      expect(actions, [ChatAssistantStrings.generatePdfLabel]);
    });
  });

  group('GenerateBudgetPdfFromChatUsecase', () {
    test(
      'não assinante aguarda o intersticial e seleciona o orçamento',
      () async {
        final ads = _FakeAds(shouldShowAds: true);
        final budgetRepo = _FakeBudgetRepo();
        final draft = CustomerInfo(id: 'abc');
        final r =
            await GenerateBudgetPdfFromChatUsecase(
              _FakeChatRepo(draft),
              budgetRepo,
              ads,
            )();
        expect(r, isA<Ok<void>>());
        expect(ads.waited, 1);
        expect(budgetRepo.selectBudget.value, same(draft));
      },
    );

    test('assinante não vê anúncio', () async {
      final ads = _FakeAds(shouldShowAds: false);
      await GenerateBudgetPdfFromChatUsecase(
        _FakeChatRepo(CustomerInfo(id: 'abc')),
        _FakeBudgetRepo(),
        ads,
      )();
      expect(ads.waited, 0);
    });

    test('sem rascunho retorna erro e não mostra anúncio', () async {
      final ads = _FakeAds(shouldShowAds: true);
      final r =
          await GenerateBudgetPdfFromChatUsecase(
            _FakeChatRepo(null),
            _FakeBudgetRepo(),
            ads,
          )();
      expect(r, isA<Error<void>>());
      expect(ads.waited, 0);
    });
  });
}
