import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;

/// Fonte de dados remota para orçamentos (Firebase Firestore).
///
/// Não conhece `Entity`; trabalha apenas com `Map<String, dynamic>`
/// (parse de JSON). A conversão para models/entities acontece no
/// `BudgetRepositoryImpl`.
class BudgetRemoteDataSource {
  final FirebaseFirestore _firestore;

  BudgetRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _budgetsCollection =>
      _firestore.collection('EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS');

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final snapshot =
        await _budgetsCollection.orderBy('ID', descending: true).get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getBudgetById(String id) async {
    final doc = await _budgetsCollection.doc(id).get();
    final data = doc.data();
    // Preserva comportamento original: se doc não existe, retorna vazio
    // em vez de lançar (o repository/VM decide como tratar).
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveBudget(Map<String, dynamic> data) async {
    final id = data['ID'] as String?;
    if (id == null) throw Exception('ID is required');
    await _budgetsCollection.doc(id).set(data);
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    await _budgetsCollection.doc(id).update(data);
  }

  Future<void> deleteBudget(String id) async {
    await _budgetsCollection.doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getBudgetItems(String budgetId) async {
    final snapshot = await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .orderBy('CATEGORIA', descending: false)
        .get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> saveBudgetItem(
      String budgetId, String itemId, Map<String, dynamic> data) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .doc(itemId)
        .set(data);
  }

  Future<void> deleteBudgetItem(String budgetId, String itemId) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('ITENS')
        .doc(itemId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getComments(String budgetId) async {
    final snapshot =
        await _budgetsCollection.doc(budgetId).collection('OBSERVACAO').get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> addComment(String budgetId, Map<String, dynamic> data) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('OBSERVACAO')
        .doc()
        .set(data);
  }

  Future<void> deleteComment(String budgetId, String commentId) async {
    await _budgetsCollection
        .doc(budgetId)
        .collection('OBSERVACAO')
        .doc(commentId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getItemsByBudgetId(String budgetId) async {
    // alias para duplicação
    return getBudgetItems(budgetId);
  }

  /// Busca orçamentos cujo ID (timestamp) está dentro do range de datas.
  Future<List<Map<String, dynamic>>> getBudgetsByMonthRange(
      String startId, String endId) async {
    final snapshot = await _budgetsCollection
        .where('ID', isGreaterThanOrEqualTo: startId)
        .where('ID', isLessThanOrEqualTo: endId)
        .orderBy('ID', descending: false)
        .get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }
}
