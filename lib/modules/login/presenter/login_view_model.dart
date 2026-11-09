import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/login/data/model/info_user.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/login/presenter/strings/login_pt_string.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginField { email, password }

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = getIt<UserRepository>();
  final PdfRepository _pdfRepository = getIt<PdfRepository>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<String> productLists =
      Platform.isAndroid
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
    } on _LoginCancelledException catch (_) {
      state = LoginState.idle;
    } on GoogleSignInException catch (e) {
      state = LoginState.error;
      debugPrint(
        'GoogleSignInException no _performLogin: ${e.code} - ${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        errorMessage =
            'Erro de configuração do Google Sign-In. Verifique se o app está assinado com o certificado correto.';
      } else if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
        errorMessage =
            'A tela de login do Google não está disponível no momento. Tente novamente.';
      } else {
        errorMessage = 'Erro no login com Google. Tente novamente.';
      }
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

        final prefs = await SharedPreferences.getInstance();
        final storedPassword = prefs.getString('password');
        final isGoogle = storedPassword == null || storedPassword == 'NO_PASS';

        final session =
            InfoUser()
              ..USER = uid
              ..NOME = currentUser.displayName ?? 'User'
              ..Senha = isGoogle ? 'NO_PASS' : storedPassword
              ..googleAuth = isGoogle
              ..EMAIL = currentUser.email ?? prefs.getString('email') ?? '';
        _userRepository.selectUser.value = session;

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
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google Sign-In retornou idToken nulo ou vazio.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      await _signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GoogleSignInException: code=${e.code}, description=${e.description}, details=${e.details}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw _LoginCancelledException();
      }
      rethrow;
    } catch (e, stack) {
      debugPrint('Erro inesperado no Google Sign-In: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    final prefs = await SharedPreferences.getInstance();
    final auth = await _auth.signInWithCredential(credential);

    await prefs.setString('email', auth.user?.email ?? '');
    await prefs.setString('password', 'NO_PASS');

    uid = auth.user?.uid ?? '';
    final session =
        InfoUser()
          ..USER = uid
          ..EMAIL = auth.user?.email
          ..NOME = auth.user?.displayName ?? 'User'
          ..Senha = 'NO_PASS'
          ..googleAuth = true;
    _userRepository.selectUser.value = session;

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

    uid = auth.user!.uid.toString();
    final session =
        InfoUser()
          ..USER = uid
          ..EMAIL = email
          ..Senha = password.trim()
          ..googleAuth = false;
    _userRepository.selectUser.value = session;

    await _getUserInfo();
  }

  Future<InfoUser?> _getUserInfo() async {
    final result = await _userRepository.getUserInfo(uid);
    if (result is Ok<InfoUser?>) {
      final user = result.value;
      if (user != null) {
        // Preserva Senha e googleAuth que nunca vêm do Firestore
        final prev = _userRepository.selectUser.value;
        if (prev != null) {
          user.Senha = prev.Senha;
          user.googleAuth = prev.googleAuth;
        }
        users = user;
        _userRepository.selectUser.value = user;
      }
      final ownerUid = _userRepository.selectUser.value?.USER;
      if (ownerUid != null && ownerUid.isNotEmpty) {
        final tokens = await getIt<NotificationRepository>().loadFcmTokens(
          ownerUid,
        );
        users.TOKENS = tokens;
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

          final session = _userRepository.selectUser.value ?? InfoUser();
          session.autoRenewing = latestSubscription.isAutoRenewing;
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
          session.autoRenewing = false;
          session.PurchaseToken = '';
          _userRepository.selectUser.value = session;
        }
      } catch (_) {
        final session = _userRepository.selectUser.value ?? InfoUser();
        session.autoRenewing = false;
        session.PurchaseToken = '';
        _userRepository.selectUser.value = session;
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
    DADOS.id = value?.uid ?? '';
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

/// Exceção interna para sinalizar que o usuário cancelou o fluxo
/// de login (ex.: fechou o picker do Google Sign-In).
class _LoginCancelledException implements Exception {}
