import 'package:cloud_firestore/cloud_firestore.dart';

/// Biblioteca de comentários do usuário no Firestore
/// (`EMPRESAS/{uid}/USERS/{uid}/COMENTARIOS`). Só `Map`.
class CommentLibraryRemoteDatasource {
  final FirebaseFirestore _firestore;

  CommentLibraryRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userUid) =>
      _firestore.collection('EMPRESAS/$userUid/USERS/$userUid/COMENTARIOS');

  /// Mais recentes primeiro. Datas vêm como [DateTime] (ou `null`).
  Future<List<Map<String, dynamic>>> getComments(String userUid) async {
    final snapshot =
        await _collection(userUid).orderBy('ATUALIZADOEM', descending: true).get();
    return [
      for (final d in snapshot.docs)
        {
          ...d.data(),
          'id': d.id,
          'CRIADOEM': (d.data()['CRIADOEM'] as Timestamp?)?.toDate(),
          'ATUALIZADOEM': (d.data()['ATUALIZADOEM'] as Timestamp?)?.toDate(),
        },
    ];
  }

  /// Grava `NOME`/`TEXTO` com `CRIADOEM`/`ATUALIZADOEM` do servidor; devolve o id.
  Future<String> addComment(String userUid, Map<String, dynamic> data) async {
    final ref = await _collection(userUid).add({
      ...data,
      'CRIADOEM': FieldValue.serverTimestamp(),
      'ATUALIZADOEM': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateComment(
    String userUid,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _collection(
      userUid,
    ).doc(id).update({...data, 'ATUALIZADOEM': FieldValue.serverTimestamp()});
  }

  Future<void> deleteComments(String userUid, List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_collection(userUid).doc(id));
    }
    await batch.commit();
  }
}
