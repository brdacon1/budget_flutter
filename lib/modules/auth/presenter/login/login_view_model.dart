import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/modules/auth/domain/exception/auth_cancelled_exception.dart';
import 'package:oflite/modules/auth/domain/usecase/restore_session_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_email_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_social_usecase.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum LoginField { email, password }

/// `checkingSession`: abertura da tela, verificando sessão/credenciais
/// salvas. A View mostra só um loading em tela cheia (sem botões).
enum LoginState { checkingSession, idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final SignInEmailUseCase _signInEmail = getIt<SignInEmailUseCase>();
  final SignInSocialUseCase _signInSocial = getIt<SignInSocialUseCase>();
  final RestoreSessionUseCase _restoreSession = getIt<RestoreSessionUseCase>();
  final UserRepository _userRepository = getIt<UserRepository>();
  final AuthRepository _authRepository = getIt<AuthRepository>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<String> productLists =
      Platform.isAndroid
          ? [
            Environment.instance.subscription.androidSku,
            Environment.instance.subscription.androidYearSku,
          ]
          : [
            Environment.instance.subscription.iosSku,
            Environment.instance.subscription.iosYearSku,
          ];

  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;

  bool isPasswordVisible = true;
  LoginField? selectedField;

  LoginState state = LoginState.checkingSession;
  String? errorMessage;

  bool rememberMe = true;

  /// Envia o e-mail de recuperação de senha.
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _authRepository.sendPasswordReset(email);
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  /// Login com Apple só em dispositivos Apple.
  final bool showAppleLogin = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  bool _initialized = false;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    rememberMe = prefs.getBool('remember_me') ?? true;

    try {
      await getIt<InAppPurchaseRepository>().initConnection();
      await getIt<InAppPurchaseRepository>().fetchProducts(skus: productLists);
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

  /// Sessão sem nome válido (vazio ou o padrão "Usuário"/"User").
  bool get needsUserName {
    final name = (_userRepository.selectUser.value?.name ?? '').trim();
    return name.isEmpty || name == LoginStrings.userFallback;
  }

  void consumeState() {
    state = LoginState.idle;
    errorMessage = null;
  }

  Future<void> toggleRememberMe() async {
    rememberMe = !rememberMe;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
    notifyListeners();
  }

  Future<void> loginWithEmailAndPassword(BuildContext context) async {
    await _performLogin(
      () => _signInEmail(
        emailController.text,
        passwordController.text,
        rememberMe: rememberMe,
      ),
    );
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    await _performLogin(() => _signInSocial(SocialProvider.google));
  }

  Future<void> loginWithApple() async {
    await _performLogin(() => _signInSocial(SocialProvider.apple));
  }

  Future<void> _performLogin(Future<void> Function() action) async {
    state = LoginState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      state = LoginState.success;
    } on FirebaseAuthException catch (e) {
      state = LoginState.error;
      errorMessage = _mapFirebaseAuthError(e);
    } on AuthCancelledException catch (_) {
      state = LoginState.idle;
    } on GoogleSignInException catch (e) {
      state = LoginState.error;
      debugPrint(
        'GoogleSignInException no _performLogin: ${e.code} - ${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        errorMessage = LoginStrings.loginErrorGoogleConfig;
      } else if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
        errorMessage = LoginStrings.loginErrorGoogleUnavailable;
      } else {
        errorMessage = LoginStrings.loginErrorGoogleDefault;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint(
        'SignInWithAppleAuthorizationException: ${e.code} - ${e.message}',
      );
      state = LoginState.error;
      errorMessage = LoginStrings.loginErrorAppleDefault;
    } catch (e, stack) {
      debugPrint('Erro inesperado no login: $e\n$stack');
      state = LoginState.error;
      errorMessage = LoginStrings.loginErrorDefault;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _checkAutoLogin() async {
    final loggedIn = await _restoreSession(rememberMe: rememberMe);
    if (_disposed) return;
    state = loggedIn ? LoginState.success : LoginState.idle;
    notifyListeners();
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
    _disposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
