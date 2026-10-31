import 'package:oflite/modules/chat_assistant/domain/usecase/chat_menu_result.dart';

/// Processa a opção escolhida no submenu "Lista de preço".
class HandlePriceListMenuOptionUsecase {
  const HandlePriceListMenuOptionUsecase();

  ChatMenuResult call(String option) {
    switch (option) {
      case '1':
        return const ChatMenuResult('priceListMenu', navigation: 'open_price_list');
      case '2':
        return const ChatMenuResult('priceListMenu', navigation: 'open_product_creator');
      case '0':
        return const ChatMenuResult('mainMenu');
      default:
        return const ChatMenuResult('priceListMenu');
    }
  }
}
