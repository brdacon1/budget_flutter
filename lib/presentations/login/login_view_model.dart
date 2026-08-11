import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/models/global_uid_user.dart' as global_uid_user;
import 'package:oflite/common/strings/auth_strings.dart';
import 'package:oflite/models/info_user.dart';
import 'package:oflite/services/http_request.dart';
import 'package:oflite/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoginField { email, password }

enum LoginState { idle, loading, success, error }

class LoginViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HttpRequest _httpRequest = HttpRequest();

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

    // A consulta de produtos de assinatura pode falhar (ex.: dispositivo
    // sem Google Play Services, emulador, rede indisponível) e lança
    // `[query-product]: Failed to query product`. Isolamos essas chamadas
    // em try/catch para que a falha NUNCA bloqueie o auto-login abaixo —
    // manter o usuário conectado (e-mail/senha, Google, cadastro) é mais
    // importante e independe das compras in-app.
    try {
      await FlutterInappPurchase.instance.initConnection();
      await FlutterInappPurchase.instance.fetchProducts<ProductSubscription>(
        skus: productLists,
        type: ProductQueryType.Subs,
      );
    } catch (_) {
      // Falha ao consultar produtos não deve impedir o login automático.
    }

    await _checkAutoLogin();
  }

  void selectField(LoginField field) {
    selectedField = field;
    // Qualquer interação manual com os campos cancela um estado
    // de erro anterior, evitando reexibir o modal de erro.
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

  /// Consome o estado atual de erro/sucesso, voltando para [LoginState.idle]
  /// **sem** disparar notificação. Usado pela UI para garantir que um
  /// estado terminal seja tratado apenas uma vez (one-shot).
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
      errorMessage = AuthStrings.loginErrorDefault;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _checkAutoLogin() async {
    // 1) Sessão do Firebase ainda ativa? O Firebase persiste o usuário
    //    autenticado entre execuções do app (e-mail/senha, Google e cadastro).
    //    Reutilizar `currentUser` é o caminho mais confiável para manter a
    //    pessoa conectada — funciona igual para os três fluxos de login.
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        state = LoginState.loading;
        notifyListeners();

        uid = currentUser.uid;

        // Descobre se a sessão veio de um login Google (senha "NO_PASS" ou
        // inexistente) para espelhar as flags que o login manual populava.
        final prefs = await SharedPreferences.getInstance();
        final storedPassword = prefs.getString('password');
        final isGoogle =
            storedPassword == null || storedPassword == 'NO_PASS';

        global_uid_user.password = isGoogle ? 'NO_PASS' : storedPassword;
        global_uid_user.googleAuth = isGoogle;
        if (!isGoogle) {
          global_uid_user.email =
              currentUser.email ?? prefs.getString('email') ?? '';
        }

        await _getUserInfo();
        state = LoginState.success;
      } catch (e) {
        state = LoginState.idle;
      } finally {
        notifyListeners();
      }
      return;
    }

    // 2) Sessão do Firebase expirou: tenta re-autenticar com e-mail/senha
    //    salvos. (Login Google não guarda senha, então só re-autentica se
    //    houver senha real — o `NO_PASS` é ignorado aqui.)
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

    final user = await _getUserInfo();

    if (user.USER != auth.user?.uid) {
      await _httpRequest.createUserWithGoogle(auth.user, null);
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
    global_uid_user.googleAuth = false;

    await _getUserInfo();
  }

  Future<InfoUser> _getUserInfo() async {
    final snapshot =
        await _firestore
            .collection('USUARIOS')
            .where('USER', isEqualTo: uid)
            .get();

    for (final element in snapshot.docs) {
      final obj = element.data();
      users.USER = obj['USER'];
      users.NOME = obj['NOME'];
      users.EMAIL = obj['EMAIL'];
      users.FONE = obj['FONE'];
      users.Id = obj['Id'];
      users.IdPay = obj['IdPay'];
      users.ProductId = obj['ProductId'];
      users.PurchaseToken = obj['PurchaseToken'];
      users.AutoRenewing = obj['AutoRenewing'] ?? false;

      global_uid_user.user = obj['USER'];
      global_uid_user.name = obj['NOME'] ?? 'User';
      global_uid_user.email = obj['EMAIL'];
      global_uid_user.phone = obj['FONE'];
      global_uid_user.id = obj['Id'];
      global_uid_user.idPay = obj['IdPay'];
      global_uid_user.productId = obj['ProductId'];
      global_uid_user.purchaseToken = obj['PurchaseToken'];
      global_uid_user.autoRenewing = obj['AutoRenewing'] ?? false;
    }

    // Inicia a escuta de notificações de aprovação/reprovação vindas do
    // fluxo Web: o dono é notificado (push local) quando um cliente
    // aprova/reprova um orçamento pela URL compartilhada. Aditivo, não muda
    // o fluxo de login existente.
    final ownerUid = global_uid_user.user;
    if (kDebugMode) {
      debugPrint('[_getUserInfo] Firebase Auth uid (query USUARIOS): "$uid"');
      debugPrint('[_getUserInfo] docs encontrados: ${snapshot.docs.length}');
      debugPrint('[_getUserInfo] global_uid_user.user (ownerUid): "$ownerUid"');
    }
    if (ownerUid != null && ownerUid.isNotEmpty) {
      // Lista de tokens FCM push do dono (um por dispositivo). Expõe nos
      // "dados do usuário" (`InfoUser.TOKENS` / `global_uid_user.tokens`).
      // A persistência do token atual (idempotente) acontece dentro de
      // `startBudgetApprovalListener` -> `_persistFcmToken`, que grava em
      // `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}`. Assim, sempre que
      // o app inicia/faz login, o token atual vai para a lista — não
      // importa em quantos devices a pessoa esteja conectada.
      final tokens = await NotificationService.instance.loadFcmTokens(ownerUid);
      users.TOKENS = tokens;
      global_uid_user.tokens = tokens;
      NotificationService.instance.startBudgetApprovalListener(ownerUid);
    }
    // Após o login (manual ou auto-login), o dono está autenticado e o
    // navigator/logo em seguida estará pronto: tenta consumir um orçamento
    // pendente de abrir (cold-start pelo toque no banner da notificação).
    NotificationService.instance.tryOpenPendingBudget();

    // A consulta de assinaturas (`getAvailablePurchases`) pode falhar
    // (sem Play Services, emulador, rede) exatamente como `fetchProducts`.
    // Isolamos em try/catch para que a falha NUNCA quebre o fluxo de
    // login/cadastro/auto-login — o usuário já está autenticado no Firebase
    // e com o documento lido; a assinatura é complementar.
    try {
      final resultSubscription =
          await FlutterInappPurchase.instance.getAvailablePurchases();

      if (resultSubscription.isNotEmpty) {
        final latestSubscription = resultSubscription.reduce(
          (current, next) =>
              (current.transactionDate) > (next.transactionDate)
                  ? current
                  : next,
        );

        global_uid_user.autoRenewing = latestSubscription.isAutoRenewing;
        global_uid_user.purchaseToken = latestSubscription.purchaseToken ?? '';
        global_uid_user.productId = latestSubscription.productId;

        if (Platform.isAndroid &&
            latestSubscription is PurchaseAndroid &&
            latestSubscription.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
            latestSubscription.purchaseToken ?? '',
          );
        }
      } else {
        global_uid_user.autoRenewing = false;
        global_uid_user.purchaseToken = '';
      }
    } catch (_) {
      // Falha ao consultar assinatura não impede o login/cadastro.
      global_uid_user.autoRenewing = false;
      global_uid_user.purchaseToken = '';
    }

    return users;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthStrings.loginErrorUserNotFound;
      case 'wrong-password':
        return AuthStrings.loginErrorWrongPassword;
      case 'invalid-email':
        return AuthStrings.loginErrorInvalidEmail;
      case 'user-disabled':
        return AuthStrings.loginErrorUserDisabled;
      default:
        return AuthStrings.loginErrorDefault;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
