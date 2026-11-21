import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/web_budget/services/web_budget_service.dart';

/// Estado de alto nível do fluxo Web de orçamento.
///
/// Interpreta a URL pública `https://dominio/o/{code}` e decide a tela:
///
/// - [BudgetWebAppPhase.blocked] → URL sem código válido.
/// - [BudgetWebAppPhase.auth]    → pede o telefone; a validação do código,
///   validade e telefone acontece no **servidor** (`openShareLink`).
/// - [BudgetWebAppPhase.access]  → servidor liberou; dados já carregados.
///
/// Nada do orçamento chega ao navegador antes do telefone conferir.
class BudgetWebAppViewModel extends ChangeNotifier {
  BudgetWebAppPhase _phase = BudgetWebAppPhase.loading;
  BudgetWebAppPhase get phase => _phase;

  String? _code;
  String? get code => _code;

  /// Telefone já validado pelo servidor — reenviado ao aprovar/reprovar.
  String? _phone;
  String? get phone => _phone;

  SharedBudget? _shared;
  SharedBudget? get shared => _shared;

  String? _errorTitle;
  String? get errorTitle => _errorTitle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void parse(Uri url) {
    final code = WebBudgetService.codeFromUri(url);
    if (code == null) {
      fail(BudgetWebStrings.blockedMessage);
      return;
    }
    _code = code;
    _phase = BudgetWebAppPhase.auth;
    notifyListeners();
  }

  /// Chamado pela tela de telefone quando o servidor libera o orçamento.
  void grantAccess({required String phone, required SharedBudget shared}) {
    _phone = phone;
    _shared = shared;
    _phase = BudgetWebAppPhase.access;
    notifyListeners();
  }

  /// Bloqueia o fluxo (link inválido/expirado/revogado ou tentativas esgotadas).
  void fail(String message) {
    _errorTitle = BudgetWebStrings.blockedTitle;
    _errorMessage = message;
    _phase = BudgetWebAppPhase.blocked;
    notifyListeners();
  }
}

enum BudgetWebAppPhase { loading, blocked, auth, access }
