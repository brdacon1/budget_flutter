import 'package:oflite/injection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/web_budget/services/web_budget_service.dart';

import '../budget_web_app/budget_web_app_view_model.dart';

/// Validação do telefone do fluxo Web.
///
/// Envia código + telefone para `openShareLink`; a comparação com o `FONE`
/// do orçamento (e o limite de tentativas) acontece no servidor. Só quando
/// o servidor libera os dados é que `grantAccess`/`onGranted` são chamados.
class BudgetWebAuthViewModel extends ChangeNotifier {
  BudgetWebAuthViewModel({required this.appViewModel, required this.onGranted});

  final BudgetWebAppViewModel appViewModel;
  final VoidCallback onGranted;

  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository _loadingEvent = getIt<LoadingEventRepository>();
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
      // O servidor confere código + validade + telefone e só então devolve
      // o orçamento. Nada é baixado se o telefone não conferir.
      final shared = await _service.open(
        code: appViewModel.code!,
        phone: digits,
      );

      if (context.mounted) _loadingEvent.closeLoading(context);
      _validating = false;
      notifyListeners();
      appViewModel.grantAccess(phone: digits, shared: shared);
      onGranted();
    } on WebBudgetAccessError catch (e) {
      if (context.mounted) _loadingEvent.closeLoading(context);
      _validating = false;
      notifyListeners();
      switch (e.kind) {
        case WebBudgetErrorKind.phone:
          if (context.mounted) {
            await _displayAlert.notificationWarning(
              context,
              BudgetWebStrings.blockedTitle,
              BudgetWebStrings.phoneInvalid,
            );
          }
        case WebBudgetErrorKind.locked:
          appViewModel.fail(BudgetWebStrings.phoneLocked);
        case WebBudgetErrorKind.invalidLink:
          appViewModel.fail(BudgetWebStrings.blockedMessage);
        case WebBudgetErrorKind.unknown:
          if (context.mounted) {
            await _displayAlert.notificationError(
              context,
              BudgetWebStrings.blockedTitle,
              BudgetWebStrings.blockedMessage,
            );
          }
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
