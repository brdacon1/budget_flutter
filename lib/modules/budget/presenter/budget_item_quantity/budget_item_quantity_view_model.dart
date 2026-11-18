import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/domain/usecase/update_budget_item_quantity_usecase.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado do modal de detalhes/quantidade de um item do orçamento.
class BudgetItemQuantityViewModel extends ChangeNotifier {
  final String budgetId;
  final ItemsBudget item;

  final UpdateBudgetItemQuantityUsecase _updateQuantityUsecase =
      getIt<UpdateBudgetItemQuantityUsecase>();
  final ConvertCoinRepository moneyConvert = getIt<ConvertCoinRepository>();

  BudgetItemQuantityViewModel({required this.budgetId, required this.item}) {
    final q = item.quantity ?? 0;
    quantityController = TextEditingController(
      text:
          q == q.roundToDouble()
              ? q.toInt().toString()
              : q.toString().replaceAll('.', ','),
    );
    saveCommand = Command0(_save);
  }

  late final TextEditingController quantityController;
  late final Command0<void> saveCommand;

  String? quantityError;

  String get description => item.description ?? '-';

  String get category =>
      ItemCategory.fromValue(item.category)?.label ?? (item.category ?? '-');

  String get measure => (item.measure ?? '').trim();

  String get price => moneyConvert.convertFromDouble(item.price ?? 0);

  double? get _quantity =>
      double.tryParse(quantityController.text.trim().replaceAll(',', '.'));

  /// Total do item recalculado ao vivo com a quantidade digitada.
  String get total =>
      moneyConvert.convertFromDouble((_quantity ?? 0) * (item.price ?? 0));

  /// Há alteração pendente (§17.5 — botão só destaca quando dirty).
  bool get dirty {
    final q = _quantity;
    return q != null && q != (item.quantity ?? 0);
  }

  void onQuantityChanged(String _) {
    quantityError = null;
    notifyListeners();
  }

  /// Valida no submit (§17.4). Erro inline, preservando o que foi digitado.
  bool validate() {
    final q = _quantity;
    if (q == null || q <= 0) {
      quantityError = BudgetStrings.itemQuantityError;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<Result<void>> _save() => _updateQuantityUsecase(
    budgetId: budgetId,
    item: item,
    quantity: _quantity ?? 0,
  );

  @override
  void dispose() {
    quantityController.dispose();
    saveCommand.dispose();
    super.dispose();
  }
}
