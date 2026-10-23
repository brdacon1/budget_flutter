import 'package:flutter/material.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/product/product_price_list/presenter/product_price_list_view.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MainConfigMenuViewModel extends ChangeNotifier {
  final DisplayAlert _displayAlert = DisplayAlert();

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: 'Lista de preço'),
    MenuItem(icon: Icons.picture_as_pdf_outlined, title: 'Editar PDF'),
    MenuItem(icon: Icons.person_pin_outlined, title: 'Trocar nome de usuário'),
  ];

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductPriceListView(fromMenu: true),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PdfEditView(),
          ),
        );
        break;
      case 2:
        _displayAlert.dialogChangeName(context);
        break;
    }
  }

}
