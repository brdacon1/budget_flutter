import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/web_budget/budget_web/budget_web_auth/budget_web_auth_view.dart';
import 'package:oflite/modules/web_budget/budget_web/budget_web_app/budget_web_app_view_model.dart';
import 'package:oflite/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view.dart';
import 'components/budget_web_app_blocked_view.dart';

/// Raiz do fluxo Web de orçamento.
///
/// Interpreta a URL pública (`/o/{code}`), pede o telefone e
/// apresenta, conforme o estado:
///
/// - `loading`  → spinner;
/// - `blocked`  → tela de bloqueio (link inválido/expirado);
/// - `auth`     → tela de validação do telefone (segunda camada de segurança);
/// - `access`   → orçamento completo (Meus dados / Itens / PDF).
///
/// É o "home" do `main_web.dart` — as demais telas do app mobile nunca são
/// expostas no Web.
class BudgetWebAppView extends StatefulWidget {
  const BudgetWebAppView({super.key});

  @override
  State<BudgetWebAppView> createState() => _BudgetWebAppViewState();
}

class _BudgetWebAppViewState extends State<BudgetWebAppView> {
  final BudgetWebAppViewModel _viewModel = getIt<BudgetWebAppViewModel>();

  @override
  void initState() {
    super.initState();
    // No Flutter Web, `Uri.base` reflete a URL atual do navegador
    // (ex.: https://dominio/o/Xk9fQ2mL7aBcDeFg).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.parse(Uri.base);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          switch (_viewModel.phase) {
            case BudgetWebAppPhase.loading:
              return const Center(
                child: CircularProgressIndicator(
                  color: buttonColor,
                ),
              );
            case BudgetWebAppPhase.blocked:
              return BudgetWebAppBlockedView(
                title: _viewModel.errorTitle ?? BudgetWebStrings.blockedTitle,
                message: _viewModel.errorMessage ?? BudgetWebStrings.blockedMessage,
              );
            case BudgetWebAppPhase.auth:
              return BudgetWebAuthView(
                viewModel: _viewModel,
                // A tela de telefone já chama `grantAccess` com os dados
                // liberados pelo servidor; aqui não há nada a fazer.
                onGranted: () {},
              );
            case BudgetWebAppPhase.access:
              return BudgetWebBudgetView(
                code: _viewModel.code!,
                phone: _viewModel.phone!,
                shared: _viewModel.shared!,
              );
          }
        },
      ),
    );
  }
}
