import 'package:firebase_auth/firebase_auth.dart';

/// Fonte de dados para geração do link de compartilhamento.
///
/// Acessa o [FirebaseAuth] para obter o token do usuário.
class ShareLinkDataSource {
  /// Obtém o ID Token atual do usuário logado.
  Future<String?> getCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }
}
