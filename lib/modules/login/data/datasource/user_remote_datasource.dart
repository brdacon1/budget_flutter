import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/login/data/model/info_user.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    final snapshot =
        await _firestore.collection('USUARIOS').where('USER', isEqualTo: uid).get();
    if (snapshot.docs.isEmpty) return null;
    return Map<String, dynamic>.from(snapshot.docs.first.data());
  }

  Future<void> saveUser(InfoUser user) async {
    await _firestore.collection('USUARIOS').doc(user.USER).set({
      'USER': user.USER,
      'FONE': user.FONE,
      'EMAIL': user.EMAIL,
      'NOME': user.NOME,
      'Id': user.Id,
      'AutoRenewing': user.AutoRenewing,
      'IdPay': user.IdPay,
      'ProductId': user.ProductId,
      'PurchaseToken': user.PurchaseToken,
    });
  }

  Future<void> updateUser(InfoUser user) async {
    await _firestore.collection('USUARIOS').doc(user.USER).update({
      'USER': user.USER,
      'FONE': user.FONE,
      'EMAIL': user.EMAIL,
      'NOME': user.NOME,
      'Id': user.Id,
      'AutoRenewing': user.AutoRenewing,
      'IdPay': user.IdPay,
      'ProductId': user.ProductId,
      'PurchaseToken': user.PurchaseToken,
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
