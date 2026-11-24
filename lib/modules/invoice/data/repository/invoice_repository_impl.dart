import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/invoice/data/datasource/invoice_remote_datasource.dart';
import 'package:oflite/modules/invoice/data/datasource/invoice_storage_datasource.dart';
import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/payment_proof/data/datasource/proof_file_local_datasource.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDatasource _remote;
  final InvoiceStorageDatasource _storage;
  final ProofFileLocalDatasource _local;
  final UserRepository _userRepository;

  InvoiceRepositoryImpl(
    this._remote,
    this._storage,
    this._local,
    this._userRepository,
  );

  String? get _uid => _userRepository.selectUser.value?.user;

  Exception get _noUser => Exception('User not authenticated');

  @override
  Future<Result<List<Invoice>>> fetchInvoices(String budgetId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      final raw = await _remote.getInvoices(uid, budgetId);
      return Result.ok(raw.map(Invoice.fromJson).toList());
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<int>> countInvoices(String budgetId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      return Result.ok(await _remote.countInvoices(uid, budgetId));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<Invoice>> saveInvoice({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    required double value,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    final isPdf = type == PaymentProofType.pdf;
    final path = isPdf ? localPath : await _local.compressImage(localPath);
    final storagePath = InvoiceStorageDatasource.pathFor(
      uid,
      budgetId,
      id,
      isPdf ? 'pdf' : 'jpg',
    );
    String? uploaded;
    try {
      final url = await _storage.upload(
        storagePath,
        path,
        isPdf ? 'application/pdf' : 'image/jpeg',
      );
      uploaded = storagePath;
      final invoice = Invoice(
        id: id,
        name: name,
        value: value,
        type: type,
        fileUrl: url,
        storagePath: storagePath,
        size: await _local.sizeOf(path),
        createdAt: createdAt,
        origin: origin.value,
      );
      await _remote.saveInvoice(uid, budgetId, id, invoice.toJson());
      return Result.ok(invoice);
    } catch (e) {
      if (uploaded != null) {
        try {
          await _storage.delete(uploaded);
        } catch (_) {}
      }
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteInvoice(String budgetId, Invoice invoice) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      await _remote.deleteInvoice(uid, budgetId, invoice.id);
      try {
        await _storage.delete(invoice.storagePath);
      } catch (_) {}
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
