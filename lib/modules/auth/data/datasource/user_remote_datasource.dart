import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRemoteDataSource({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final snapshot =
        await _firestore
            .collection('USUARIOS')
            .where('USER', isEqualTo: uid)
            .get();
    if (snapshot.docs.isEmpty) return null;
    return _normalize(snapshot.docs.first.data());
  }

  /// Timestamps do Firestore viram milissegundos (o domínio não conhece o SDK).
  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['TrialStartedAt', 'LastSeenAt']) {
      final v = map[key];
      if (v is Timestamp) map[key] = v.millisecondsSinceEpoch;
    }
    return map;
  }

  /// Garante `TrialStartedAt` (só na primeira vez, com hora do servidor) e
  /// devolve início do trial e "agora" do servidor, em milissegundos.
  /// `null` se o documento do usuário ainda não existe.
  Future<({int trialStartedAt, int serverNow})?> syncTrial(String uid) async {
    final query =
        await _firestore
            .collection('USUARIOS')
            .where('USER', isEqualTo: uid)
            .get();
    if (query.docs.isEmpty) return null;
    final ref = query.docs.first.reference;
    final hasTrial = query.docs.first.data()['TrialStartedAt'] != null;
    await ref.set({
      if (!hasTrial) 'TrialStartedAt': FieldValue.serverTimestamp(),
      'LastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final fresh = _normalize(
      (await ref.get(const GetOptions(source: Source.server))).data() ?? {},
    );
    final start = fresh['TrialStartedAt'];
    final now = fresh['LastSeenAt'];
    if (start is! int || now is! int) return null;
    return (trialStartedAt: start, serverNow: now);
  }

  Future<void> saveUser(InfoUser user) async {
    await _firestore.collection('USUARIOS').doc(user.user).set({
      'USER': user.user,
      'FONE': user.phone,
      'EMAIL': user.email,
      'NOME': user.name,
      'Id': user.id,
      'AutoRenewing': user.autoRenewing,
      'IdPay': user.idPay,
      'ProductId': user.productId,
      'PurchaseToken': user.purchaseToken,
    }, SetOptions(merge: true));
  }

  Future<void> updateUser(InfoUser user) async {
    await _firestore.collection('USUARIOS').doc(user.user).update({
      'USER': user.user,
      'FONE': user.phone,
      'EMAIL': user.email,
      'NOME': user.name,
      'Id': user.id,
      'AutoRenewing': user.autoRenewing,
      'IdPay': user.idPay,
      'ProductId': user.productId,
      'PurchaseToken': user.purchaseToken,
      if (user.segment != null) 'Segmento': user.segment,
    });
  }

  Future<void> savePdfInfo(OwnerPdf pdf, String userId) async {
    await _firestore
        .collection('EMPRESAS/$userId/USERS/$userId/INFOPDF')
        .doc('INFORMATION')
        .set({
          'EMPRESA': pdf.empresa,
          'EMAIL': pdf.email,
          'CNPJ': pdf.cnpj,
          'RUA': pdf.rua,
          'BAIRRO': pdf.bairro,
          'CITY': pdf.city,
          'CEP': pdf.cep,
          'FOTOID': pdf.fotoId,
          'FONE': pdf.fone,
          'LOGONAME': pdf.logoName,
        });
  }

  Future<String> getIdToken() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 'NOT_AUTH';
    final idToken = await currentUser.getIdToken();
    return idToken ?? 'NOT_AUTH';
  }
}
