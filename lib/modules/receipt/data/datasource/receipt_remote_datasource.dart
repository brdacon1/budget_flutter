import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptRemoteDatasource {
  final FirebaseFirestore _firestore;

  ReceiptRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _receiptsCollection(String userUid, String budgetId) =>
      _firestore.collection(
        'EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS/$budgetId/RECIBOS',
      );

  Future<List<Map<String, dynamic>>> getReceipts(
    String userUid,
    String budgetId,
  ) async {
    final snapshot = await _receiptsCollection(userUid, budgetId).get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data() as Map);
      map['id'] = d.id;
      return map;
    }).toList();
  }

  /// Todos os recibos do usuário (de todos os orçamentos) em 1 consulta
  /// `collectionGroup`, limitada ao caminho `EMPRESAS/{uid}/USERS/{uid}/`.
  /// Cada item traz `id`, `budgetId` (tirado do caminho) e os campos.
  Future<List<Map<String, dynamic>>> getAllUserReceipts(String userUid) async {
    final prefix = 'EMPRESAS/$userUid/USERS/$userUid/';
    final snapshot =
        await _firestore
            .collectionGroup('RECIBOS')
            .orderBy(FieldPath.documentId)
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      map['budgetId'] = d.reference.parent.parent?.id;
      return map;
    }).toList();
  }

  /// IDs dos orçamentos do usuário (fallback quando o `collectionGroup` não
  /// está liberado nas regras/índices do Firestore).
  Future<List<String>> getBudgetIds(String userUid) async {
    final snapshot =
        await _firestore
            .collection('EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS')
            .get();
    return snapshot.docs.map((d) => d.id).toList();
  }

  Future<void> saveReceipt(
    String userUid,
    String budgetId,
    Map<String, dynamic> data,
    String id,
  ) async {
    await _receiptsCollection(userUid, budgetId).doc(id).set(data);
  }

  Future<void> deleteReceipt(String userUid, String budgetId, String id) async {
    await _receiptsCollection(userUid, budgetId).doc(id).delete();
  }
}
