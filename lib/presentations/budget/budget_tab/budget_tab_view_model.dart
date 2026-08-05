import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:oflite/models/customer_info.dart';

class BudgetTabViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void onTabTapped(int index, BuildContext context, double we, CustomerInfo item) {
    if (index == 0) {
      _currentIndex = index;
    } else {
      if (item.id!.isNotEmpty) {
        _currentIndex = index;
      } else {
        AwesomeDialog(
          width: we * 0.99,
          context: context,
          dialogBackgroundColor: Colors.cyan[50],
          animType: AnimType.leftSlide,
          headerAnimationLoop: false,
          dialogType: DialogType.warning,
          showCloseIcon: false,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          descTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          title: 'Ainda não!',
          desc:
              'É necessário cadastrar o cliente colocando pelo menos o nome e clicar no botão "Continuar"',
          btnOkOnPress: () async {},
          btnOkIcon: Icons.check_circle,
        ).show();
      }
    }
    notifyListeners();
  }
}
