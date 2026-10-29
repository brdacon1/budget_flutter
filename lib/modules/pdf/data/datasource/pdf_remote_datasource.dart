import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

class PdfRemoteDataSource {
  final FirebaseFirestore _firestore;
  PdfRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getInformationEnterprise() async {
    final doc = await _firestore
        .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/INFOPDF')
        .doc('INFORMATION')
        .get();
    final data = doc.data();
    // Se o usuário ainda não possui INFOPDF, retorna map vazio para que
    // OwnerPdf.fromJson(null) monte um objeto com campos em branco
    // (preserva comportamento anterior ao refatoramento do datasource legado).
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveInformationEnterprise(Map<String, dynamic> data) async {
    await _firestore
        .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/INFOPDF')
        .doc('INFORMATION')
        .set(data);
  }

  Future<void> updateInformationEnterprise(Map<String, dynamic> data) async {
    await _firestore
        .collection('EMPRESAS/${UID.user}/USERS/${UID.user}/INFOPDF')
        .doc('INFORMATION')
        .update(data);
  }
}
