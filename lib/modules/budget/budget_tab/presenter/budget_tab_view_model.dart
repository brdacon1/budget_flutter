import 'package:oflite/injection.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';

class BudgetTabViewModel extends ChangeNotifier {
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();
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
