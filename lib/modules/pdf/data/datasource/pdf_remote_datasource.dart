import 'package:cloud_firestore/cloud_firestore.dart';

class PdfRemoteDataSource {
  final FirebaseFirestore _firestore;
  PdfRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getInformationEnterprise(String userUid) async {
    final doc = await _firestore
        .collection('EMPRESAS/$userUid/USERS/$userUid/INFOPDF')
        .doc('INFORMATION')
        .get();
    final data = doc.data();
    // Se o usuário ainda não possui INFOPDF, retorna map vazio para que
    // OwnerPdf.fromJson(null) monte um objeto com campos em branco
    // (preserva comportamento anterior ao refatoramento do datasource legado).
    if (data == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveInformationEnterprise(String userUid, Map<String, dynamic> data) async {
    await _firestore
        .collection('EMPRESAS/$userUid/USERS/$userUid/INFOPDF')
        .doc('INFORMATION')
        .set(data);
  }

  Future<void> updateInformationEnterprise(String userUid, Map<String, dynamic> data) async {
    await _firestore
        .collection('EMPRESAS/$userUid/USERS/$userUid/INFOPDF')
        .doc('INFORMATION')
        .update(data);
  }
}
