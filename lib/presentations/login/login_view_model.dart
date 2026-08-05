import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/models/global_uid_user.dart' as global_uid_user;
import 'package:oflite/models/info_user.dart';
import 'package:oflite/services/http_request.dart';
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

    await FlutterInappPurchase.instance.initConnection();
    await FlutterInappPurchase.instance.fetchProducts<ProductSubscription>(
      skus: productLists,
      type: ProductQueryType.Subs,
    );

    await _checkAutoLogin();
  }

  void selectField(LoginField field) {
    selectedField = field;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
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
      errorMessage =
          'Problemas para realizar seu login. Verifique sua senha e e-mail.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (email != null && password != null && password != 'NO_PASS') {
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

    return users;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Usuário desativado.';
      default:
        return 'Problemas para realizar seu login. Verifique sua senha e e-mail.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
