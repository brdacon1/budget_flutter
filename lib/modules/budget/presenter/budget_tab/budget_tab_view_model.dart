import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';

class BudgetTabViewModel extends ChangeNotifier {
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
        AlertSnackBar.warning(
          context,
          'Ainda não!',
          'É necessário cadastrar o cliente colocando pelo menos o nome e clicar no botão "Continuar"',
        );
      }
    }
    notifyListeners();
  }
}
