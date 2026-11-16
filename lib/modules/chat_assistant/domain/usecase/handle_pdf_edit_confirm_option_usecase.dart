import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_pdf_edit_menu_usecase.dart';

/// Processa a opção de confirmação após editar um campo PDF.
class HandlePdfEditConfirmOptionUsecase {
  final ShowPdfEditMenuUsecase _showPdfEditMenu;

  const HandlePdfEditConfirmOptionUsecase(this._showPdfEditMenu);

  Future<ChatMenuResult> call(String option) async {
    switch (option) {
      case '1':
        return ChatMenuResult(await _showPdfEditMenu());
      case '2':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('pdfEditConfirm');
    }
  }
}
