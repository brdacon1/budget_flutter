import 'package:flutter/material.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/presentations/comment/comment_list_view.dart';
import 'package:oflite/presentations/receipt/receipt_list/receipt_list_view.dart';

class MenuItem {
  final IconData icon;
  final String title;

  const MenuItem({required this.icon, required this.title});
}

class PdfMenuViewModel extends ChangeNotifier {
  final DisplayAlert displayAlert = DisplayAlert();
  final CustomerInfo item;

  List<MenuItem> menuItems = <MenuItem>[];

  PdfMenuViewModel({required this.item});

  Future<void> inicialData() async {
    menuItems = const <MenuItem>[
      MenuItem(icon: Icons.comment_outlined, title: 'Inserir comentários'),
      MenuItem(icon: Icons.payments_outlined, title: 'Recibo de pagamentos'),
    ];
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  Future<void> openOption(BuildContext context, int index) async {
    switch (index) {
      case 0:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentListView(item: item),
          ),
        );
        break;
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptListView(item: item),
          ),
        );
        break;
    }
    await inicialData();
  }
}
