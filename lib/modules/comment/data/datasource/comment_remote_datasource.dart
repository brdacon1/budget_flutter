import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

class CommentRemoteDataSource {
  final FirebaseFirestore _firestore;
  CommentRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _collection(String budgetId) => _firestore
      .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/$budgetId/OBSERVACAO');

  Future<List<Map<String, dynamic>>> getComments(String budgetId) async {
    final snapshot = await _collection(budgetId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> addComment(String budgetId, Map<String, dynamic> data) async {
    await _collection(budgetId).doc().set(data);
  }

  Future<void> updateComment(
      String budgetId, String commentId, Map<String, dynamic> data) async {
    await _collection(budgetId).doc(commentId).update(data);
  }

  Future<void> deleteComment(String budgetId, String commentId) async {
    await _collection(budgetId).doc(commentId).delete();
  }
}
