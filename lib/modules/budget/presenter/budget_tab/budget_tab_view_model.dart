import 'package:oflite/injection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';

class BudgetTabViewModel extends ChangeNotifier {
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();
  int currentIndex = 0;

  void onTabTapped(
    int index,
    BuildContext context,
    double we,
    CustomerInfo item,
  ) {
    if (index == 0) {
      currentIndex = index;
    } else {
      if (item.id != null && item.id!.isNotEmpty) {
        currentIndex = index;
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
