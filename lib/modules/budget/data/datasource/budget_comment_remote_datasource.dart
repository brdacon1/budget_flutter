import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCommentRemoteDatasource {
  final FirebaseFirestore _firestore;

  BudgetCommentRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _collection(String userUid, String budgetId) =>
      _firestore.collection(
        'EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS/$budgetId/OBSERVACAO',
      );

  Future<List<Map<String, dynamic>>> getComments(
    String userUid,
    String budgetId,
  ) async {
    final snapshot = await _collection(userUid, budgetId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> addComment(
    String userUid,
    String budgetId,
    Map<String, dynamic> data,
  ) async {
    await _collection(userUid, budgetId).doc().set(data);
  }

  Future<void> updateComment(
    String userUid,
    String budgetId,
    String commentId,
    Map<String, dynamic> data,
  ) async {
    await _collection(userUid, budgetId).doc(commentId).update(data);
  }

  Future<void> deleteComment(
    String userUid,
    String budgetId,
    String commentId,
  ) async {
    await _collection(userUid, budgetId).doc(commentId).delete();
  }
}
