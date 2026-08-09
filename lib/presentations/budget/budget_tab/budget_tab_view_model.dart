import 'package:flutter/material.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/services/display_alert.dart';

class BudgetTabViewModel extends ChangeNotifier {
  final DisplayAlert _displayAlert = DisplayAlert();
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void onTabTapped(int index, BuildContext context, double we, CustomerInfo item) {
    if (index == 0) {
      _currentIndex = index;
    } else {
      if (item.id != null && item.id!.isNotEmpty) {
        _currentIndex = index;
      } else {
        _displayAlert.notificationWarning(
          context,
          'Ainda não!',
          'É necessário cadastrar o cliente colocando pelo menos o nome e clicar no botão "Continuar"',
        );
      }
    }
    notifyListeners();
  }
}
