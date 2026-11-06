import 'package:cloud_firestore/cloud_firestore.dart';

/// Fonte de dados remota para mensagens de sessão do chat.
///
/// Grava em:
/// `EMPRESAS/{uid}/USERS/{uid}/CHAT_SESSIONS/{sessionId}/MESSAGES/{msgId}`
class ChatBudgetRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatBudgetRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _messagesCollection(String userUid, String sessionId) => _firestore
      .collection(
          'EMPRESAS/$userUid/USERS/$userUid/CHAT_SESSIONS/$sessionId/MESSAGES');

  DocumentReference _sessionDoc(String userUid, String sessionId) => _firestore
      .collection('EMPRESAS/$userUid/USERS/$userUid/CHAT_SESSIONS')
      .doc(sessionId);

  /// Cria o documento de sessão.
  Future<void> createSession(
      String userUid, String sessionId, Map<String, dynamic> meta) async {
    await _sessionDoc(userUid, sessionId).set(meta);
  }

  /// Salva uma mensagem na sessão.
  Future<void> saveMessage(
      String userUid, String sessionId, Map<String, dynamic> data) async {
    await _messagesCollection(userUid, sessionId).add(data);
  }

  /// Busca mensagens de uma sessão ordenadas por timestamp.
  Future<List<Map<String, dynamic>>> fetchMessages(String userUid, String sessionId) async {
    final snapshot = await _messagesCollection(userUid, sessionId)
        .orderBy('timestamp', descending: false)
        .get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }
}
