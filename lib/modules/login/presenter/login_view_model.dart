import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as global_uid_user;
import 'package:oflite/modules/login/presenter/strings/login_pt_string.dart';
import 'package:oflite/modules/login/data/model/info_user.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum LoginField { email, password }

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = getIt<UserRepository>();
  final PdfRepository _pdfRepository = getIt<PdfRepository>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<String> productLists = Platform.isAndroid
      ? ['newproduct']
      : ['com.housestudio.oflite', 'com.housestudio.oflite'];

  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;

  bool isPasswordVisible = true;
  LoginField? selectedField;
  String uid = '';
  InfoUser users = InfoUser();

  LoginState state = LoginState.idle;
  String? errorMessage;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await getIt<InAppPurchaseRepository>().initConnection();
      await getIt<InAppPurchaseRepository>().fetchProducts<ProductSubscription>(
        skus: productLists,
      );
    } catch (_) {}

    await _checkAutoLogin();
  }

  void selectField(LoginField field) {
    selectedField = field;
    if (state == LoginState.error) {
      state = LoginState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    if (state == LoginState.error) {
      state = LoginState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  void consumeState() {
    state = LoginState.idle;
    errorMessage = null;
  }

  Future<void> loginWithEmailAndPassword(BuildContext context) async {
    await _performLogin(
      context,
      () => _emailAndPassword(emailController.text, passwordController.text),
    );
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    await _performLogin(context, _signInWithGoogle);
  }

  Future<void> _performLogin(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    state = LoginState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      state = LoginState.success;
    } on FirebaseAuthException catch (e) {
      state = LoginState.error;
      errorMessage = _mapFirebaseAuthError(e);
    } catch (e) {
      state = LoginState.error;
      errorMessage = LoginStrings.loginErrorDefault;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _checkAutoLogin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        state = LoginState.loading;
        notifyListeners();

        uid = currentUser.uid;
        global_uid_user.user = uid;
        global_uid_user.name = currentUser.displayName ?? 'User';

        final prefs = await SharedPreferences.getInstance();
        final storedPassword = prefs.getString('password');
        final isGoogle =
            storedPassword == null || storedPassword == 'NO_PASS';

        global_uid_user.password = isGoogle ? 'NO_PASS' : storedPassword;
        global_uid_user.googleAuth = isGoogle;
        global_uid_user.email =
            currentUser.email ?? prefs.getString('email') ?? '';

        await _getUserInfo();
        state = LoginState.success;
      } catch (e) {
        state = LoginState.idle;
      } finally {
        notifyListeners();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (email == null || password == null || password == 'NO_PASS') return;

    try {
      state = LoginState.loading;
      notifyListeners();
      await _emailAndPassword(email, password);
      state = LoginState.success;
    } catch (e) {
      state = LoginState.idle;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _signInWithCredential(credential);
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    final prefs = await SharedPreferences.getInstance();
    final auth = await _auth.signInWithCredential(credential);

    await prefs.setString('email', auth.user?.email ?? '');
    await prefs.setString('password', 'NO_PASS');

    global_uid_user.password = 'NO_PASS';
    global_uid_user.googleAuth = true;
    uid = auth.user?.uid ?? '';
    global_uid_user.user = uid;
    global_uid_user.email = auth.user?.email;
    global_uid_user.name = auth.user?.displayName ?? 'User';

    final user = await _getUserInfo();

    if (user?.USER != auth.user?.uid) {
      await _createUserWithGoogle(auth.user);
    }
  }

  Future<void> _emailAndPassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final auth = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    await prefs.setString('email', email);
    await prefs.setString('password', password);

    global_uid_user.password = password.trim();
    uid = auth.user!.uid.toString();
    global_uid_user.user = uid;
    global_uid_user.email = email;
    global_uid_user.googleAuth = false;

    await _getUserInfo();
  }

  Future<InfoUser?> _getUserInfo() async {
    final result = await _userRepository.getUserInfo(uid);
    if (result is Ok<InfoUser?>) {
      final user = result.value;
      if (user != null) {
        users = user;
        global_uid_user.user = user.USER;
        global_uid_user.name = user.NOME ?? 'User';
        global_uid_user.email = user.EMAIL;
        global_uid_user.phone = user.FONE;
        global_uid_user.id = user.Id;
        global_uid_user.idPay = user.IdPay;
        global_uid_user.productId = user.ProductId;
        global_uid_user.purchaseToken = user.PurchaseToken;
        global_uid_user.autoRenewing = user.AutoRenewing;
      }
      final ownerUid = global_uid_user.user;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        final tokens =
            await getIt<NotificationRepository>().loadFcmTokens(ownerUid);
        users.TOKENS = tokens;
        global_uid_user.tokens = tokens;
        getIt<NotificationRepository>().startBudgetApprovalListener(ownerUid);
      }
      getIt<NotificationRepository>().tryOpenPendingBudget();

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

          global_uid_user.autoRenewing = latestSubscription.isAutoRenewing;
          global_uid_user.purchaseToken =
              latestSubscription.purchaseToken ?? '';
          global_uid_user.productId = latestSubscription.productId;

          if (Platform.isAndroid &&
              latestSubscription is PurchaseAndroid &&
              latestSubscription.isAcknowledgedAndroid != true) {
            await getIt<InAppPurchaseRepository>().acknowledgePurchaseAndroid(
              latestSubscription.purchaseToken ?? '',
            );
          }
        } else {
          global_uid_user.autoRenewing = false;
          global_uid_user.purchaseToken = '';
        }
      } catch (_) {
        global_uid_user.autoRenewing = false;
        global_uid_user.purchaseToken = '';
      }

      return user;
    }
    return null;
  }

  Future<void> _createUserWithGoogle(User? value) async {
    final DADOS = InfoUser();
    final PDF = OwnerPdf();
    DADOS.EMAIL = value?.email ?? '';
    DADOS.FONE = value?.phoneNumber ?? '';
    DADOS.USER = value?.uid ?? '';
    DADOS.NOME = value?.displayName ?? '';
    DADOS.Id = value?.uid ?? '';
    PDF.email = value?.email ?? '';
    PDF.empresa = "Minha Empresa";
    PDF.logoName = '';
    PDF.fotoId = '';
    await _userRepository.createDefaultUserData(DADOS, PDF);
    await _pdfRepository.saveInformationEnterprise(PDF);
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return LoginStrings.loginErrorUserNotFound;
      case 'wrong-password':
        return LoginStrings.loginErrorWrongPassword;
      case 'invalid-email':
        return LoginStrings.loginErrorInvalidEmail;
      case 'user-disabled':
        return LoginStrings.loginErrorUserDisabled;
      default:
        return LoginStrings.loginErrorDefault;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
