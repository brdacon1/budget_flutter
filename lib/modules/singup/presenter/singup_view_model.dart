import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/login/data/model/info_user.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/singup/presenter/strings/singup_pt_string.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      errorMessage = SingUpStrings.signUpErrorFillAll;
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
      DADOS.id = uid;
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

      final session =
          InfoUser()
            ..USER = uid
            ..NOME = nome
            ..EMAIL = email
            ..FONE = DADOS.FONE
            ..id = uid
            ..Senha = password
            ..googleAuth = false
            ..IdPay = ''
            ..ProductId = ''
            ..PurchaseToken = ''
            ..AutoRenewing = false;
      _userRepository.selectUser.value = session;

      await _getUserInfo(uid);

      state = SingUpState.success;
    } on FirebaseAuthException catch (e) {
      state = SingUpState.error;
      errorMessage = _mapFirebaseAuthError(e);
    } catch (e) {
      state = SingUpState.error;
      errorMessage = SingUpStrings.signUpErrorDefault;
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
        DADOS.id = user.id;
        DADOS.IdPay = user.IdPay;
        DADOS.ProductId = user.ProductId;
        DADOS.PurchaseToken = user.PurchaseToken;
        DADOS.AutoRenewing = user.AutoRenewing;

        _userRepository.selectUser.value = user;
      } else {
        final fallback = _userRepository.selectUser.value ?? InfoUser();
        fallback.USER = uid;
        _userRepository.selectUser.value = fallback;
      }

      final ownerUid = _userRepository.selectUser.value?.USER;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        final tokens = await getIt<NotificationRepository>().loadFcmTokens(
          ownerUid,
        );
        DADOS.TOKENS = tokens;
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

          final session = _userRepository.selectUser.value ?? InfoUser();
          session.AutoRenewing = latestSubscription.isAutoRenewing;
          session.PurchaseToken = latestSubscription.purchaseToken ?? '';
          session.ProductId = latestSubscription.productId;
          _userRepository.selectUser.value = session;

          if (Platform.isAndroid &&
              latestSubscription is PurchaseAndroid &&
              latestSubscription.isAcknowledgedAndroid != true) {
            await getIt<InAppPurchaseRepository>().acknowledgePurchaseAndroid(
              latestSubscription.purchaseToken ?? '',
            );
          }
        } else {
          final session = _userRepository.selectUser.value ?? InfoUser();
          session.AutoRenewing = false;
          session.PurchaseToken = '';
          _userRepository.selectUser.value = session;
        }
      } catch (_) {
        final session = _userRepository.selectUser.value ?? InfoUser();
        session.AutoRenewing = false;
        session.PurchaseToken = '';
        _userRepository.selectUser.value = session;
      }

      return user;
    }
    return null;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return SingUpStrings.signUpErrorEmailInUse;
      case 'invalid-email':
        return SingUpStrings.signUpErrorInvalidEmail;
      case 'weak-password':
        return SingUpStrings.signUpErrorWeakPassword;
      case 'operation-not-allowed':
        return SingUpStrings.signUpErrorDisabled;
      default:
        return SingUpStrings.signUpErrorDefault;
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
