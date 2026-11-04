import 'package:cloud_firestore/cloud_firestore.dart';

/// Fonte de dados remota para o script de mensagens do bot.
///
/// Lê o documento `EMPRESAS/{uid}/CONFIG/CHAT_SCRIPT/DEFAULT`.
/// Não conhece Entity; trabalha apenas com Map/Dynamic.
class ChatScriptRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatScriptRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _scriptDoc(String userUid) => _firestore
      .collection('EMPRESAS/$userUid/CONFIG')
      .doc('CHAT_SCRIPT');

  /// Retorna o mapa do script ou null se não existir.
  Future<Map<String, dynamic>?> getScript(String userUid) async {
    final doc = await _scriptDoc(userUid).get();
    final data = doc.data();
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }
}
