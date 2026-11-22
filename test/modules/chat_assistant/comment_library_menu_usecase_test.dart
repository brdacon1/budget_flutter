import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/handle_comment_library_menu_option_usecase.dart';

void main() {
  const usecase = HandleCommentLibraryMenuOptionUsecase();

  test('1 abre a lista, 2 abre o criar, 0 volta ao menu', () {
    expect(usecase('1').navigation, HandleCommentLibraryMenuOptionUsecase.openListNav);
    expect(usecase('2').navigation, HandleCommentLibraryMenuOptionUsecase.openCreatorNav);
    expect(usecase('0').nextStep, 'mainMenu');
    expect(usecase('9').navigation, isNull);
    expect(usecase('9').nextStep, 'commentLibraryMenu');
  });
}
