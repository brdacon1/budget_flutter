import 'package:flutter/foundation.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_payment_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/datasource/receipt_remote_datasource.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/domain/entity/receipt_ledger.dart';
import 'package:oflite/modules/receipt/domain/repository/receipt_ledger_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

typedef _Raw =
    ({
      List<Map<String, dynamic>> receipts,
      List<Map<String, dynamic>> payments,
    });

class ReceiptLedgerRepositoryImpl implements ReceiptLedgerRepository {
  final ReceiptRemoteDatasource _receipts;
  final ReceiptPaymentRemoteDatasource _payments;
  final UserRepository _user;
  final DateTime Function() _clock;

  ReceiptLedgerRepositoryImpl(
    this._receipts,
    this._payments,
    this._user, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Telas de recibo gravam sem passar por aqui: cache curto evita dado velho.
  static const cacheTtl = Duration(minutes: 1);

  ReceiptLedger? _cache;
  DateTime? _cachedAt;
  String? _cachedUid;

  @override
  void invalidate() => _cache = null;

  @override
  Future<Result<ReceiptLedger>> fetchLedger({bool forceRefresh = false}) async {
    final uid = _user.selectUser.value?.user;
    if (uid == null || uid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    final cache = _cache;
    if (!forceRefresh &&
        cache != null &&
        _cachedUid == uid &&
        _clock().difference(_cachedAt!) < cacheTtl) {
      return Result.ok(cache);
    }
    try {
      final raw = await _loadGrouped(uid) ?? await _loadPerBudget(uid);
      final ledger = build(raw.receipts, raw.payments);
      _cache = ledger;
      _cachedAt = _clock();
      _cachedUid = uid;
      return Result.ok(ledger);
    } catch (e) {
      debugPrint('[ReceiptLedger] erro: $e');
      return Result.error(Exception(e.toString()));
    }
  }

  /// 2 consultas `collectionGroup`. Null se o Firestore recusar (regras ou
  /// índice de collection group ainda não publicados).
  Future<_Raw?> _loadGrouped(String uid) async {
    try {
      final results = await Future.wait([
        _receipts.getAllUserReceipts(uid),
        _payments.getAllUserPayments(uid),
      ]);
      return (receipts: results[0], payments: results[1]);
    } catch (e) {
      debugPrint('[ReceiptLedger] collectionGroup falhou, usando fallback: $e');
      return null;
    }
  }

  /// Fallback: orçamento a orçamento (mais leituras, mas usa as regras atuais).
  Future<_Raw> _loadPerBudget(String uid) async {
    final budgetIds = await _receipts.getBudgetIds(uid);
    final receipts = <Map<String, dynamic>>[];
    final payments = <Map<String, dynamic>>[];
    await Future.wait([
      for (final budgetId in budgetIds)
        () async {
          final list = await _receipts.getReceipts(uid, budgetId);
          for (final r in list) {
            receipts.add({...r, 'budgetId': budgetId});
          }
          await Future.wait([
            for (final r in list)
              () async {
                final receiptId = r['id'] as String;
                final pays = await _payments.getPayments(
                  uid,
                  budgetId,
                  receiptId,
                );
                for (final p in pays) {
                  payments.add({
                    ...p,
                    'budgetId': budgetId,
                    'receiptId': receiptId,
                  });
                }
              }(),
          ]);
        }(),
    ]);
    return (receipts: receipts, payments: payments);
  }

  /// Junta pagamentos ao recibo pelo caminho (`budgetId`/`receiptId`).
  /// Pagamento órfão é ignorado.
  static ReceiptLedger build(
    List<Map<String, dynamic>> rawReceipts,
    List<Map<String, dynamic>> rawPayments,
  ) {
    final pays = <String, List<PaymentCustomer>>{};
    for (final p in rawPayments) {
      final key = '${p['budgetId']}/${p['receiptId']}';
      pays
          .putIfAbsent(key, () => [])
          .add(
            PaymentCustomer(
              id: p['id'] as String?,
              method: p['METODO'] as String?,
              description: p['DESCRICAO'] as String?,
              price: (p['PRECO'] as num?)?.toDouble(),
            ),
          );
    }
    final byBudget = <String, List<LedgerReceipt>>{};
    for (final r in rawReceipts) {
      final budgetId = r['budgetId'] as String?;
      final docId = r['id'] as String?;
      if (budgetId == null || docId == null) continue;
      final receipt = Receipt.fromJson(r).copyWith(id: docId);
      final createdAt = createdAtOf(docId, receipt.data);
      if (createdAt == null) continue;
      byBudget
          .putIfAbsent(budgetId, () => [])
          .add(
            LedgerReceipt(
              receipt: receipt,
              budgetId: budgetId,
              createdAt: createdAt,
              payments: pays['$budgetId/$docId'] ?? const [],
            ),
          );
    }
    return ReceiptLedger(byBudget);
  }

  /// O ID do recibo é o timestamp (ms) de criação; legado → `DATA` dd/MM/yyyy.
  static DateTime? createdAtOf(String id, String? data) {
    final ms = int.tryParse(id);
    if (ms != null && ms > 946684800000) {
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(data ?? '');
    if (m == null) return null;
    return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }
}
