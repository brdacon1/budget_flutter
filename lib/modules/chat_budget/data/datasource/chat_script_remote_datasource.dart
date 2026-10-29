import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

/// Fonte de dados remota para o script de mensagens do bot.
///
/// Lê o documento `EMPRESAS/{uid}/CONFIG/CHAT_SCRIPT/DEFAULT`.
/// Não conhece Entity; trabalha apenas com Map/Dynamic.
class ChatScriptRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatScriptRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference get _scriptDoc => _firestore
      .collection('EMPRESAS/${UID.user}/CONFIG')
      .doc('CHAT_SCRIPT');

  /// Retorna o mapa do script ou null se não existir.
  Future<Map<String, dynamic>?> getScript() async {
    final doc = await _scriptDoc.get();
    final data = doc.data();
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }
}
