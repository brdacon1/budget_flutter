import 'package:oflite/injection.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/product/product_price_list/presenter/product_price_list_view.dart';
import 'package:oflite/modules/main_config_menu/presenter/strings/main_config_menu_pt_string.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MainConfigMenuViewModel extends ChangeNotifier {
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: MainConfigMenuStrings.menuPriceList),
    MenuItem(icon: Icons.picture_as_pdf_outlined, title: MainConfigMenuStrings.menuEditPdf),
    MenuItem(icon: Icons.person_pin_outlined, title: MainConfigMenuStrings.menuChangeUsername),
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
