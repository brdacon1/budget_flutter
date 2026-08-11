import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/web/budget_web/budget_web_auth/budget_web_auth_view.dart';
import 'package:oflite/web/budget_web/budget_web_app/budget_web_app_view_model.dart';
import 'package:oflite/web/budget_web/budget_web_budget/budget_web_budget_view.dart';
import 'components/budget_web_app_blocked_view.dart';

/// Raiz do fluxo Web de orçamento.
///
/// Interpreta a URL pública, valida o token provisório do Firebase e
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
  final BudgetWebAppViewModel _viewModel = BudgetWebAppViewModel();

  @override
  void initState() {
    super.initState();
    // No Flutter Web, `Uri.base` reflete a URL atual do navegador
    // (ex.: https://dominio/orcamento/123?token=ABC).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.parseAndValidate(Uri.base);
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
                onGranted: () => _viewModel.grantAccess(),
              );
            case BudgetWebAppPhase.access:
              return BudgetWebBudgetView(
                enderecoNumero: _viewModel.enderecoNumero!,
                ownerUid: _viewModel.ownerUid!,
                token: _viewModel.token!,
              );
          }
        },
      ),
    );
  }
}
