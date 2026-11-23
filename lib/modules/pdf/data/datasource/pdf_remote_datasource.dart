import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oflite/shared/common/utils/dio_client.dart';

class PdfRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Dio _dio;

  PdfRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Dio? dio,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _dio = dio ?? DioClient().dioClientAuth;

  Future<Map<String, dynamic>> getInformationEnterprise(String userUid) async {
    final doc =
        await _firestore
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

  Future<void> saveInformationEnterprise(
    String userUid,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('EMPRESAS/$userUid/USERS/$userUid/INFOPDF')
        .doc('INFORMATION')
        .set(data);
  }

  Future<void> updateInformationEnterprise(
    String userUid,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('EMPRESAS/$userUid/USERS/$userUid/INFOPDF')
        .doc('INFORMATION')
        .update(data);
  }

  /// ID token do usuário logado no Firebase Auth (null se não houver sessão).
  Future<String?> getCurrentIdToken() async => _auth.currentUser?.getIdToken();

  /// Reautentica com e-mail/senha e devolve o novo ID token.
  Future<String?> signInAndGetIdToken(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user?.getIdToken();
  }

  /// URL pública do logo no Firebase Storage.
  ///
  /// `fotoId` novo já é a URL completa (token embutido); dados antigos guardam
  /// só o token e a URL é montada a partir do `logoName`.
  String logoUrl(String fotoId, String? logoName) =>
      fotoId.startsWith('http')
          ? fotoId
          : 'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/'
              '${Uri.encodeComponent(logoName ?? '')}?alt=media&token=$fotoId';

  /// Baixa o logo do Firebase Storage. Retorna null se o status não for 200.
  /// [bearerToken] null = sem header Authorization (Web, evita preflight CORS).
  Future<({Uint8List bytes, bool isImage})?> downloadLogo(
    String url, {
    String? bearerToken,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json;odata=verbose',
    };
    if (bearerToken != null) headers['Authorization'] = 'Bearer $bearerToken';

    final response = await _dio.get(url, options: Options(headers: headers));
    if (response.statusCode != 200) return null;
    return (
      bytes: response.data as Uint8List,
      isImage:
          response.headers.value('content-type')?.startsWith('image/') == true,
    );
  }
}
