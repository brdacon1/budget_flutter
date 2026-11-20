import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage dos arquivos de comprovante:
/// `comprovantes/{uid}/{budgetId}/{id}.{ext}`.
class PaymentProofStorageDatasource {
  final FirebaseStorage _storage;

  PaymentProofStorageDatasource({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  static String pathFor(String uid, String budgetId, String id, String ext) =>
      'comprovantes/$uid/$budgetId/$id.$ext';

  /// Envia o arquivo e devolve a URL de download.
  Future<String> upload(String storagePath, String localPath, String mime) async {
    final ref = _storage.ref(storagePath);
    await ref.putFile(File(localPath), SettableMetadata(contentType: mime));
    return ref.getDownloadURL();
  }

  Future<void> delete(String storagePath) async {
    if (storagePath.isEmpty) return;
    await _storage.ref(storagePath).delete();
  }
}
