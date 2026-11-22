import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/show_comment_library_menu_usecase.dart';

/// Processa a opção escolhida no submenu "Cadastrar comentários".
class HandleCommentLibraryMenuOptionUsecase {
  const HandleCommentLibraryMenuOptionUsecase();

  static const openListNav = 'open_comment_library';
  static const openCreatorNav = 'open_comment_creator';

  ChatMenuResult call(String option) {
    const step = ShowCommentLibraryMenuUsecase.step;
    return switch (option) {
      '1' => const ChatMenuResult(step, navigation: openListNav),
      '2' => const ChatMenuResult(step, navigation: openCreatorNav),
      '0' => const ChatMenuResult('mainMenu'),
      _ => const ChatMenuResult(step),
    };
  }
}
