import 'package:get_it/get_it.dart';
import 'package:oflite/modules/web_budget/budget_web/budget_web_app/budget_web_app_view_model.dart';

/// Registra as dependências do módulo WebBudget.
///
/// Apenas [BudgetWebAppViewModel] é registrado aqui porque os demais
/// ViewModels do fluxo Web recebem parâmetros no construtor
/// (ex.: [BudgetWebAuthViewModel], [BudgetWebBudgetViewModel]).
void registerWebBudgetDependencies(GetIt sl) {
  sl.registerFactory<BudgetWebAppViewModel>(() => BudgetWebAppViewModel());
}
