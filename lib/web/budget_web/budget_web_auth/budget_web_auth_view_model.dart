import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';
import 'package:oflite/web/services/web_budget_service.dart';

import '../budget_web_app/budget_web_app_view_model.dart';

/// Validação do telefone (segunda camada de segurança do fluxo Web).
///
/// Recebe o `BudgetWebAppViewModel` (que já validou o token e localizou o
/// orçamento). Compara os dígitos do telefone informado com o `FONE`
/// cadastrado no orçamento. Só em caso de correspondência chama
/// `onGranted` para liberar o acesso — nenhum dado é exibido antes disso.
class BudgetWebAuthViewModel extends ChangeNotifier {
  BudgetWebAuthViewModel({required this.appViewModel, required this.onGranted});

  final BudgetWebAppViewModel appViewModel;
  final VoidCallback onGranted;

  final DisplayAlert _displayAlert = DisplayAlert();
  final LoadingEvent _loadingEvent = LoadingEvent();
  final WebBudgetService _service = WebBudgetService();

  final phoneController = TextEditingController();
  final phoneNode = FocusNode();
  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _validating = false;
  bool get validating => _validating;

  Future<void> validate(BuildContext context) async {
    final raw = phoneController.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      await _displayAlert.notificationWarning(
        context,
        BudgetWebStrings.blockedTitle,
        BudgetWebStrings.phoneRequired,
      );
      return;
    }

    _validating = true;
    notifyListeners();
    _loadingEvent.alertLoading(context);

    try {
      // Busca novamente o orçamento (com o token já validado) e compara o
      // telefone. O número do endereço localiza; o telefone só valida.
      final budget = await _service.getBudget(
        ownerUid: appViewModel.ownerUid!,
        enderecoNumero: appViewModel.enderecoNumero!,
        token: appViewModel.token!,
      );
      final budgetDigits = (budget.phone ?? '').replaceAll(RegExp(r'\D'), '');

      if (context.mounted) _loadingEvent.closeLoading(context);

      if (budgetDigits.isEmpty || budgetDigits != digits) {
        _validating = false;
        notifyListeners();
        if (context.mounted) {
          await _displayAlert.notificationWarning(
            context,
            BudgetWebStrings.blockedTitle,
            BudgetWebStrings.phoneInvalid,
          );
        }
        return;
      }

      _validating = false;
      notifyListeners();
      onGranted();
    } on WebBudgetAccessError catch (e) {
      if (context.mounted) _loadingEvent.closeLoading(context);
      _validating = false;
      notifyListeners();
      if (context.mounted) {
        await _displayAlert.notificationError(
          context,
          BudgetWebStrings.blockedTitle,
          e.kind == WebBudgetErrorKind.notFound
              ? BudgetWebStrings.blockedMessage
              : e.message,
        );
      }
    } catch (_) {
      if (context.mounted) _loadingEvent.closeLoading(context);
      _validating = false;
      notifyListeners();
      if (context.mounted) {
        await _displayAlert.notificationError(
          context,
          BudgetWebStrings.blockedTitle,
          BudgetWebStrings.blockedMessage,
        );
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    phoneNode.dispose();
    super.dispose();
  }
}
