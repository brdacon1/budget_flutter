import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Leituras agregadas de **um** orçamento para a tela de métricas.
///
/// Usa `count()`/`sum()` (o servidor devolve só o número) para gastar o
/// mínimo de leituras e de dados móveis. Só trabalha com primitivos/Map.
class BudgetMetricsRemoteDatasource {
  final FirebaseFirestore _firestore;

  BudgetMetricsRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _budgetPath(String uid, String budgetId) =>
      'EMPRESAS/$uid/USERS/$uid/ORCAMENTOS/$budgetId';

  CollectionReference<Map<String, dynamic>> _col(
    String uid,
    String budgetId,
    String name,
  ) => _firestore.collection('${_budgetPath(uid, budgetId)}/$name');

  /// Agregação no servidor; se o Firestore recusar (regra/SDK), lê os
  /// documentos e calcula localmente — a tela nunca quebra por isso.
  Future<T> _aggregateOr<T>(
    String label,
    Future<T> Function() aggregate,
    Future<T> Function() fallback,
  ) async {
    try {
      return await aggregate();
    } catch (e) {
      debugPrint('[BudgetMetrics] $label agregação falhou, usando leitura: $e');
      return fallback();
    }
  }

  Future<int> _count(String uid, String budgetId, String name) {
    final col = _col(uid, budgetId, name);
    return _aggregateOr(
      name,
      () async => (await col.count().get()).count ?? 0,
      () async => (await col.get()).size,
    );
  }

  /// Itens do orçamento (só `CATEGORIA` e `TOTAL` interessam). 1 leitura
  /// por item; dispensa índice composto e serve para contar e somar.
  Future<List<Map<String, dynamic>>> items(String uid, String budgetId) async {
    final snap = await _col(uid, budgetId, 'ITENS').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  Future<int> receiptsCount(String uid, String budgetId) =>
      _count(uid, budgetId, 'RECIBOS');

  Future<int> proofsCount(String uid, String budgetId) =>
      _count(uid, budgetId, 'COMPROVANTES');

  /// Pagamentos de todos os recibos do orçamento em 1 consulta
  /// `collectionGroup` limitada ao caminho do orçamento. Se o Firestore
  /// recusar (regras/índice), cai para recibo a recibo.
  Future<List<Map<String, dynamic>>> budgetPayments(
    String uid,
    String budgetId,
  ) async {
    // O SDK exige caminho de documento válido (sem `/` no fim): os
    // pagamentos ficam entre `.../{budgetId}` e `.../{budgetId}\uf8ff`.
    final budgetPath = _budgetPath(uid, budgetId);
    try {
      final snap =
          await _firestore
              .collectionGroup('PAGAMENTOS')
              .orderBy(FieldPath.documentId)
              .startAt([_firestore.doc(budgetPath)])
              .endAt([_firestore.doc('$budgetPath\uf8ff')])
              .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[BudgetMetrics] collectionGroup falhou, usando fallback: $e');
      final receipts = await _col(uid, budgetId, 'RECIBOS').get();
      final pages = await Future.wait(
        receipts.docs.map((r) => r.reference.collection('PAGAMENTOS').get()),
      );
      return [for (final p in pages) ...p.docs.map((d) => d.data())];
    }
  }
}
