import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/payment_proof/data/datasource/payment_proof_remote_datasource.dart';
import 'package:oflite/modules/payment_proof/data/datasource/payment_proof_storage_datasource.dart';
import 'package:oflite/modules/payment_proof/data/datasource/proof_file_local_datasource.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PaymentProofRepositoryImpl implements PaymentProofRepository {
  final PaymentProofRemoteDatasource _remote;
  final PaymentProofStorageDatasource _storage;
  final ProofFileLocalDatasource _local;
  final UserRepository _userRepository;

  PaymentProofRepositoryImpl(
    this._remote,
    this._storage,
    this._local,
    this._userRepository,
  );

  String? get _uid => _userRepository.selectUser.value?.user;

  Exception get _noUser => Exception('User not authenticated');

  @override
  Future<Result<List<PaymentProof>>> fetchProofs(String budgetId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      final raw = await _remote.getProofs(uid, budgetId);
      return Result.ok(raw.map(PaymentProof.fromJson).toList());
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<int>> countProofs(String budgetId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      return Result.ok(await _remote.countProofs(uid, budgetId));
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<PaymentProof>> saveProof({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    double? value,
    String? comment,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    final isPdf = type == PaymentProofType.pdf;
    final path = isPdf ? localPath : await _local.compressImage(localPath);
    final storagePath = PaymentProofStorageDatasource.pathFor(
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
      final proof = PaymentProof(
        id: id,
        name: name,
        value: value,
        comment: comment,
        type: type,
        fileUrl: url,
        storagePath: storagePath,
        size: await _local.sizeOf(path),
        createdAt: createdAt,
        origin: origin.value,
      );
      await _remote.saveProof(uid, budgetId, id, proof.toJson());
      return Result.ok(proof);
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
  Future<Result<void>> deleteProof(String budgetId, PaymentProof proof) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return Result.error(_noUser);
    try {
      await _remote.deleteProof(uid, budgetId, proof.id);
      try {
        await _storage.delete(proof.storagePath);
      } catch (_) {}
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<int> fileSize(String path) => _local.sizeOf(path);
}
