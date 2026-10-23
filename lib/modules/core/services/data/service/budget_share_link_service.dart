import 'package:firebase_auth/firebase_auth.dart';

/// Utilitário aditivo para gerar a URL pública compartilhável de um orçamento
/// no fluxo Web.
///
/// A URL segue o formato definido em `create_flutter_web_page.md`:
///
/// ```text
/// https://dominio-web.com/orcamento/{numero-endereco}?token={firebase-token}
/// ```
///
/// - `numero-endereco` = `ID` (document id) do orçamento, o identificador que
///   o app já usa para localizá-lo no Firestore.
/// - `token` = Firebase ID Token **provisório** do dono do orçamento
///   (`getIdToken()`), válido por ~1h. É a camada de segurança do link; o
///   telefone continua sendo a segunda validação no fluxo Web.
///
/// Este serviço é **aditivo** e não está ligado a nenhuma tela mobile —
/// apenas centraliza a geração do link para uso futuro, sem alterar o
/// comportamento existente do aplicativo.
class BudgetShareLinkService {
  BudgetShareLinkService._();

  /// Domínio base onde o Flutter Web do fluxo de orçamento está publicado.
  ///
  /// Padrão = URL do Firebase Hosting do projeto `orcamentofacil-lite`
  /// (configurado em `.firebaserc`/`firebase.json`). Para apontar para um
  /// domínio próprio em produção, sobrescreva no build com:
  ///
  /// ```bash
  /// flutter build apk --release \
  ///   --dart-define=BUDGET_WEB_BASE_URL=https://orcamento.suaempresa.com.br
  /// ```
  static const String webBaseUrl = String.fromEnvironment(
    'BUDGET_WEB_BASE_URL',
    defaultValue: 'https://orcamentofacil-lite.web.app',
  );

  /// Gera a URL compartilhável para o orçamento de `enderecoNumero`,
  /// embutindo um Firebase ID Token fresco do usuário atual.
  ///
  /// Retorna `null` se não houver usuário autenticado (impossível gerar o
  /// token provisório) — o chamador decide como tratar.
  static Future<String?> buildShareUrl({
    required String enderecoNumero,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return null;
    final base = webBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/orcamento/$enderecoNumero?token=$token';
  }
}
