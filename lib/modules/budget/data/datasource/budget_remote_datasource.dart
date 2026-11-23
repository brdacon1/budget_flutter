import 'package:cloud_firestore/cloud_firestore.dart';

/// Fonte de dados remota para orçamentos (Firebase Firestore).
///
/// Não conhece `Entity`; trabalha apenas com `Map<String, dynamic>`
/// (parse de JSON). A conversão para models/entities acontece no
/// `BudgetRepositoryImpl`.
class BudgetRemoteDataSource {
  final FirebaseFirestore _firestore;

  BudgetRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _budgetsCollection(String userUid) =>
      _firestore.collection('EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS');

  Future<List<Map<String, dynamic>>> getBudgets(String userUid) async {
    final snapshot =
        await _budgetsCollection(userUid).orderBy('ID', descending: true).get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getBudgetsPaginated(
    String userUid, {
    required int limit,
    String? startAfterId,
  }) async {
    var query = _budgetsCollection(
      userUid,
    ).orderBy('ID', descending: true).limit(limit);

    if (startAfterId != null && startAfterId.isNotEmpty) {
      query = query.startAfter([startAfterId]);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }

  Future<int> countBudgets(String userUid) async {
    final aggregate = await _budgetsCollection(userUid).count().get();
    return aggregate.count ?? 0;
  }

  Future<Map<String, dynamic>> getBudgetById(String userUid, String id) async {
    final doc = await _budgetsCollection(userUid).doc(id).get();
    final data = doc.data();
    // Preserva comportamento original: se doc não existe, retorna vazio
    // em vez de lançar (o repository/VM decide como tratar).
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveBudget(String userUid, Map<String, dynamic> data) async {
    final id = data['ID'] as String?;
    if (id == null) throw Exception('ID is required');
    await _budgetsCollection(userUid).doc(id).set(data);
  }

  Future<void> updateBudget(
    String userUid,
    String id,
    Map<String, dynamic> data,
  ) async {
    await _budgetsCollection(userUid).doc(id).update(data);
  }

  Future<void> deleteBudget(String userUid, String id) async {
    await _budgetsCollection(userUid).doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> getBudgetItems(
    String userUid,
    String budgetId,
  ) async {
    final snapshot =
        await _budgetsCollection(userUid)
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
    String userUid,
    String budgetId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    await _budgetsCollection(
      userUid,
    ).doc(budgetId).collection('ITENS').doc(itemId).set(data);
  }

  Future<void> deleteBudgetItem(
    String userUid,
    String budgetId,
    String itemId,
  ) async {
    await _budgetsCollection(
      userUid,
    ).doc(budgetId).collection('ITENS').doc(itemId).delete();
  }

  Future<List<Map<String, dynamic>>> getComments(
    String userUid,
    String budgetId,
  ) async {
    final snapshot =
        await _budgetsCollection(
          userUid,
        ).doc(budgetId).collection('OBSERVACAO').get();
    return snapshot.docs.map((d) {
      final map = Map<String, dynamic>.from(d.data());
      map['id'] = d.id;
      return map;
    }).toList();
  }

  Future<void> addComment(
    String userUid,
    String budgetId,
    Map<String, dynamic> data,
  ) async {
    await _budgetsCollection(
      userUid,
    ).doc(budgetId).collection('OBSERVACAO').doc().set(data);
  }

  Future<void> deleteComment(
    String userUid,
    String budgetId,
    String commentId,
  ) async {
    await _budgetsCollection(
      userUid,
    ).doc(budgetId).collection('OBSERVACAO').doc(commentId).delete();
  }

  Future<List<Map<String, dynamic>>> getItemsByBudgetId(
    String userUid,
    String budgetId,
  ) async {
    // alias para duplicação
    return getBudgetItems(userUid, budgetId);
  }

  /// Todos os orçamentos cujo STATUS é um dos [values] (variações de caixa
  /// do mesmo status). Sem orderBy: dispensa índice composto; quem chama
  /// ordena.
  Future<List<Map<String, dynamic>>> getBudgetsByStatus(
    String userUid,
    List<String> values,
  ) async {
    final snapshot =
        await _budgetsCollection(
          userUid,
        ).where('STATUS', whereIn: values).get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }

  /// Orçamentos cujo FONE é um dos [values] (formatos do mesmo telefone),
  /// em tempo real: emite de novo a cada criação/alteração/exclusão.
  Stream<List<Map<String, dynamic>>> watchBudgetsByPhone(
    String userUid,
    List<String> values,
  ) {
    return _budgetsCollection(userUid)
        .where('FONE', whereIn: values)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => Map<String, dynamic>.from(d.data() as Map))
                  .toList(),
        );
  }

  /// Orçamentos cujo NOMECLIENTE começa com algum dos [prefixes]. O Firestore
  /// não tem "contains"/case-insensitive: uma query de range por prefixo,
  /// resultados unidos por ID.
  Future<List<Map<String, dynamic>>> searchBudgetsByNamePrefix(
    String userUid,
    List<String> prefixes,
  ) async {
    final snapshots = await Future.wait([
      for (final p in prefixes)
        _budgetsCollection(userUid)
            .where('NOMECLIENTE', isGreaterThanOrEqualTo: p)
            .where('NOMECLIENTE', isLessThan: '$p')
            .limit(100)
            .get(),
    ]);
    final byId = <String, Map<String, dynamic>>{};
    for (final s in snapshots) {
      for (final d in s.docs) {
        byId[d.id] = Map<String, dynamic>.from(d.data() as Map);
      }
    }
    return byId.values.toList();
  }

  /// Busca orçamentos cujo ID (timestamp) está dentro do range de datas.
  Future<List<Map<String, dynamic>>> getBudgetsByMonthRange(
    String userUid,
    String startId,
    String endId,
  ) async {
    final snapshot =
        await _budgetsCollection(userUid)
            .where('ID', isGreaterThanOrEqualTo: startId)
            .where('ID', isLessThanOrEqualTo: endId)
            .orderBy('ID', descending: false)
            .get();
    return snapshot.docs
        .map((d) => Map<String, dynamic>.from(d.data() as Map))
        .toList();
  }
}
