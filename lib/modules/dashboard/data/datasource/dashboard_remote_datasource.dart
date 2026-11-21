import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Leituras do dashboard que não existem em outros módulos.
class DashboardRemoteDatasource {
  final FirebaseFirestore _firestore;

  DashboardRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _budgetsPath(String uid) => 'EMPRESAS/$uid/USERS/$uid/ORCAMENTOS';

  /// Itens dos orçamentos cujo id (millis) está em [startId]..[endId], em 1
  /// consulta `collectionGroup` limitada pelo caminho. Cada item traz
  /// `budgetId`. Se o Firestore recusar (regra/índice), lê orçamento a
  /// orçamento usando [budgetIds].
  Future<List<Map<String, dynamic>>> monthItems(
    String uid,
    String startId,
    String endId,
    List<String> budgetIds,
  ) async {
    final base = _budgetsPath(uid);
    try {
      final snap =
          await _firestore
              .collectionGroup('ITENS')
              .orderBy(FieldPath.documentId)
              .startAt([_firestore.doc('$base/$startId')])
              .endAt([_firestore.doc('$base/$endId')])
              .get();
      return [
        for (final d in snap.docs)
          {...d.data(), 'budgetId': d.reference.parent.parent?.id},
      ];
    } catch (e) {
      debugPrint('[Dashboard] collectionGroup ITENS falhou, fallback: $e');
      final pages = await Future.wait(
        budgetIds.map(
          (id) async => (
            id: id,
            snap: await _firestore.collection('$base/$id/ITENS').get(),
          ),
        ),
      );
      return [
        for (final p in pages)
          for (final d in p.snap.docs) {...d.data(), 'budgetId': p.id},
      ];
    }
  }
}
