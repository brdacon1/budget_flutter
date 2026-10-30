import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as globalUIDUser;
import 'package:oflite/shared/common/strings/auth_strings.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum SingUpState { idle, loading, success, error }

class SingUpViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = getIt<UserRepository>();
  final PdfRepository _pdfRepository = getIt<PdfRepository>();

  final InfoUser DADOS = InfoUser();
  final OwnerPdf PDF = OwnerPdf();

  final TextEditingController emailText = TextEditingController();
  final TextEditingController passwordText = TextEditingController();
  final TextEditingController nomeText = TextEditingController();

  bool ispasswordev = true;

  SingUpState state = SingUpState.idle;
  String? errorMessage;

  void selectField(SingUpFieldType field) {
    if (state == SingUpState.error) {
      state = SingUpState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  void togglePasswordVisibility() {
    ispasswordev = !ispasswordev;
    if (state == SingUpState.error) {
      state = SingUpState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  void consumeState() {
    state = SingUpState.idle;
    errorMessage = null;
  }

  bool get isValid =>
      emailText.text.isNotEmpty &&
      passwordText.text.isNotEmpty &&
      nomeText.text.isNotEmpty;

  Future<void> register() async {
    if (!isValid) {
      state = SingUpState.error;
      errorMessage = AuthStrings.signUpErrorFillAll;
      notifyListeners();
      return;
    }

    state = SingUpState.loading;
    errorMessage = null;
    notifyListeners();

    final email = emailText.text.trim();
    final password = passwordText.text.trim();
    final nome = nomeText.text;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      DADOS.EMAIL = email;
      DADOS.FONE = '15991111111';
      DADOS.USER = uid;
      DADOS.NOME = nome;
      DADOS.Id = uid;
      DADOS.AutoRenewing = false;
      DADOS.IdPay = '';
      DADOS.ProductId = '';
      DADOS.PurchaseToken = '';

      PDF.email = email;
      PDF.empresa = 'Minha Empresa';
      PDF.logoName = '';
      PDF.fotoId = '';

      await _userRepository.createDefaultUserData(DADOS, PDF);
      await _pdfRepository.saveInformationEnterprise(PDF);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      await prefs.setString('password', password);

      globalUIDUser.user = uid;
      globalUIDUser.name = nome;
      globalUIDUser.email = email;
      globalUIDUser.phone = DADOS.FONE;
      globalUIDUser.id = uid;
      globalUIDUser.password = password;
      globalUIDUser.googleAuth = false;
      globalUIDUser.idPay = '';
      globalUIDUser.productId = '';
      globalUIDUser.purchaseToken = '';
      globalUIDUser.autoRenewing = false;

      await _getUserInfo(uid);

      state = SingUpState.success;
    } on FirebaseAuthException catch (e) {
      state = SingUpState.error;
      errorMessage = _mapFirebaseAuthError(e);
    } catch (e) {
      state = SingUpState.error;
      errorMessage = AuthStrings.signUpErrorDefault;
    } finally {
      notifyListeners();
    }
  }

  Future<InfoUser?> _getUserInfo(String uid) async {
    final result = await _userRepository.getUserInfo(uid);
    if (result is Ok<InfoUser?>) {
      final user = result.value;
      if (user != null) {
        DADOS.USER = user.USER;
        DADOS.NOME = user.NOME;
        DADOS.EMAIL = user.EMAIL;
        DADOS.FONE = user.FONE;
        DADOS.Id = user.Id;
        DADOS.IdPay = user.IdPay;
        DADOS.ProductId = user.ProductId;
        DADOS.PurchaseToken = user.PurchaseToken;
        DADOS.AutoRenewing = user.AutoRenewing;

        globalUIDUser.user = user.USER;
        globalUIDUser.name = user.NOME ?? 'User';
        globalUIDUser.email = user.EMAIL;
        globalUIDUser.phone = user.FONE;
        globalUIDUser.id = user.Id;
        globalUIDUser.idPay = user.IdPay;
        globalUIDUser.productId = user.ProductId;
        globalUIDUser.purchaseToken = user.PurchaseToken;
        globalUIDUser.autoRenewing = user.AutoRenewing;
      } else {
        // Usuário autenticado mas doc não encontrado: popula mínimo
        globalUIDUser.user = uid;
      }

      final ownerUid = globalUIDUser.user;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        final tokens =
            await getIt<NotificationRepository>().loadFcmTokens(ownerUid);
        DADOS.TOKENS = tokens;
        globalUIDUser.tokens = tokens;
        getIt<NotificationRepository>().startBudgetApprovalListener(ownerUid);
      }

      try {
        final resultSubscription =
            await getIt<InAppPurchaseRepository>().getAvailablePurchases();

        if (resultSubscription.isNotEmpty) {
          final latestSubscription = resultSubscription.reduce(
            (current, next) =>
                (current.transactionDate) > (next.transactionDate)
                    ? current
                    : next,
          );

          globalUIDUser.autoRenewing = latestSubscription.isAutoRenewing;
          globalUIDUser.purchaseToken =
              latestSubscription.purchaseToken ?? '';
          globalUIDUser.productId = latestSubscription.productId;

          if (Platform.isAndroid &&
              latestSubscription is PurchaseAndroid &&
              latestSubscription.isAcknowledgedAndroid != true) {
            await getIt<InAppPurchaseRepository>().acknowledgePurchaseAndroid(
              latestSubscription.purchaseToken ?? '',
            );
          }
        } else {
          globalUIDUser.autoRenewing = false;
          globalUIDUser.purchaseToken = '';
        }
      } catch (_) {
        globalUIDUser.autoRenewing = false;
        globalUIDUser.purchaseToken = '';
      }

      return user;
    }
    return null;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return AuthStrings.signUpErrorEmailInUse;
      case 'invalid-email':
        return AuthStrings.signUpErrorInvalidEmail;
      case 'weak-password':
        return AuthStrings.signUpErrorWeakPassword;
      case 'operation-not-allowed':
        return AuthStrings.signUpErrorDisabled;
      default:
        return AuthStrings.signUpErrorDefault;
    }
  }

  @override
  void dispose() {
    emailText.dispose();
    passwordText.dispose();
    nomeText.dispose();
    super.dispose();
  }
}
