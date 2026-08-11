import 'package:flutter/material.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/services/web_budget_service.dart';

/// Estado de alto nível do fluxo Web de orçamento.
///
/// Responsável por interpretar a URL pública
/// `https://dominio/orcamento/{numero-endereco}?token={firebase-token}` e
/// decidir qual tela mostrar:
///
/// - [BudgetWebAppPhase.blocked]  → link inválido/token expirado/sem endereço.
/// - [BudgetWebAppPhase.auth]     → token válido; aguarda validação do
///   telefone (segunda camada de segurança).
/// - [BudgetWebAppPhase.access]  → token + telefone válidos; orçamento liberado.
///
/// **Regra de segurança (spec):** o "número do endereço" localiza o
/// orçamento; o token Firebase valida o acesso ao link; o telefone é a
/// segunda validação. Nada é exibido antes das três checagens passarem.
class BudgetWebAppViewModel extends ChangeNotifier {
  BudgetWebAppPhase _phase = BudgetWebAppPhase.loading;
  BudgetWebAppPhase get phase => _phase;

  /// "Número do endereço" extraído da URL — identificador do orçamento no
  /// Firestore (document id = `ID`). Nunca é o telefone.
  String? _enderecoNumero;
  String? get enderecoNumero => _enderecoNumero;

  /// Token provisório do Firebase extraído da URL.
  String? _token;

  /// UID do dono do orçamento, decodificado do token JWT. Necessário para
  /// montar o path `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{id}`.
  String? _ownerUid;
  String? get ownerUid => _ownerUid;

  String? _errorTitle;
  String? get errorTitle => _errorTitle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Interpreta a [url] (path + query) e valida o token provisório.
  ///
  /// Em `MaterialApp.router` no Flutter Web a URL chega via
  /// `routeInformation.uri` — passamos para cá.
  Future<void> parseAndValidate(Uri url) async {
    _phase = BudgetWebAppPhase.loading;
    notifyListeners();

    // Path esperado: /orcamento/{numero-endereco}
    final segments = url.pathSegments;
    final orcamentoIndex = segments.indexOf('orcamento');
    final numero = orcamentoIndex >= 0 && orcamentoIndex + 1 < segments.length
        ? segments[orcamentoIndex + 1]
        : null;

    final token = url.queryParameters['token'];

    if (numero == null || numero.isEmpty) {
      _fail(BudgetWebStrings.blockedTitle, BudgetWebStrings.blockedMessage);
      return;
    }
    if (token == null || token.isEmpty) {
      _fail(BudgetWebStrings.blockedTitle, BudgetWebStrings.blockedMessage);
      return;
    }

    // Valida o token provisório: decodifica o JWT e checa expiração + uid.
    final claims = WebBudgetService.decodeIdToken(token);
    if (claims == null) {
      _fail(BudgetWebStrings.blockedTitle, BudgetWebStrings.blockedMessage);
      return;
    }
    final ownerUid = (claims['user_id'] ?? claims['sub'])?.toString();
    if (ownerUid == null || ownerUid.isEmpty) {
      _fail(BudgetWebStrings.blockedTitle, BudgetWebStrings.blockedMessage);
      return;
    }

    _enderecoNumero = numero;
    _token = token;
    _ownerUid = ownerUid;

    // Pré-localiza o orçamento para confirmar que o token realmente abre o
    // documento (o Firestore rejeita tokens inválidos com 401/403). Só assim
    // sabemos que o link é válido antes de pedir o telefone.
    try {
      await WebBudgetService().getBudget(
        ownerUid: ownerUid,
        enderecoNumero: numero,
        token: token,
      );
      _phase = BudgetWebAppPhase.auth;
      notifyListeners();
    } on WebBudgetAccessError catch (e) {
      _fail(BudgetWebStrings.blockedTitle,
          e.kind == WebBudgetErrorKind.notFound
              ? BudgetWebStrings.blockedMessage
              : e.message);
    } catch (_) {
      _fail(BudgetWebStrings.blockedTitle, BudgetWebStrings.blockedMessage);
    }
  }

  /// Chamado pela tela de autenticação quando o telefone é validado.
  void grantAccess() {
    _phase = BudgetWebAppPhase.access;
    notifyListeners();
  }

  void _fail(String title, String message) {
    _errorTitle = title;
    _errorMessage = message;
    _phase = BudgetWebAppPhase.blocked;
    notifyListeners();
  }

  /// Token de acesso (exposto apenas após a validação) para as telas internas
  /// (itens, PDF, aprovação) lerem/gravarem via REST.
  String? get token => _token;
}

enum BudgetWebAppPhase { loading, blocked, auth, access }
