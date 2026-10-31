import 'package:oflite/modules/chat_budget/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/reset_chat_to_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_pdf_edit_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_price_list_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/show_change_username_menu_usecase.dart';
import 'package:oflite/modules/chat_budget/domain/usecase/start_budget_from_menu_usecase.dart';

/// Processa a opção escolhida no menu principal.
class HandleMainMenuOptionUsecase {
  final StartBudgetFromMenuUsecase _startBudget;
  final ShowPriceListMenuUsecase _showPriceList;
  final ShowPdfEditMenuUsecase _showPdfEdit;
  final ShowChangeUsernameMenuUsecase _showChangeUsername;
  final ResetChatToMenuUsecase _resetToMenu;

  const HandleMainMenuOptionUsecase(
    this._startBudget,
    this._showPriceList,
    this._showPdfEdit,
    this._showChangeUsername,
    this._resetToMenu,
  );

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
        final step = await _startBudget();
        return ChatMenuResult(step);
      case '2':
        final step = await _showPriceList();
        return ChatMenuResult(step);
      case '3':
        final step = await _showPdfEdit();
        return ChatMenuResult(step);
      case '4':
        final step = await _showChangeUsername();
        return ChatMenuResult(step);
      default:
        final step = await _resetToMenu();
        return ChatMenuResult(step);
    }
  }
}
