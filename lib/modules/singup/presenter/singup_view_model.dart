import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as globalUIDUser;
import 'package:oflite/shared/common/strings/auth_strings.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/modules/core/services/data/service/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/shared/models/owner_pdf.dart';

/// Estado terminal do fluxo de cadastro, consumido pela View de forma
/// *one-shot* (igual ao `LoginState` do `LoginViewModel`).
enum SingUpState { idle, loading, success, error }

/// Gerenciamento de estado da tela de cadastro (SingUp).
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Espelha o [LoginViewModel] para que, ao final do cadastro, a sessão fique
/// **idêntica** a um login bem-sucedido: credenciais salvas em `SharedPreferences`,
/// `globalUIDUser` populado e usuário já autenticado no Firebase — assim o app
/// mantém a pessoa conectada e a leva direto para o `/menu`.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Não guarda `BuildContext` como campo.
/// - Não instancia `DisplayAlert`/`LoadingEvent` aqui — a UI (View) reage ao
///   [state] e mostra loading/snackbar/erro.
/// - Toda mutação de estado termina com `notifyListeners()`.
class SingUpViewModel extends ChangeNotifier {
  // --- Dependências / Services ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HttpRequest db = HttpRequest();
  final InfoUser DADOS = InfoUser();
  final OwnerPdf PDF = OwnerPdf();

  // --- Controllers dos campos ---
  final TextEditingController emailText = TextEditingController();
  final TextEditingController passwordText = TextEditingController();
  final TextEditingController nomeText = TextEditingController();

  // --- Estado visual reativo ---
  bool ispasswordev = true;

  // --- Estado do fluxo (consumido pela View) ---
  SingUpState state = SingUpState.idle;
  String? errorMessage;

  /// Registra a interação com um campo. Qualquer interação manual cancela
  /// um estado de erro anterior (igual ao login).
  void selectField(SingUpFieldType field) {
    if (state == SingUpState.error) {
      state = SingUpState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  /// Alterna a visibilidade da senha.
  void togglePasswordVisibility() {
    ispasswordev = !ispasswordev;
    if (state == SingUpState.error) {
      state = SingUpState.idle;
      errorMessage = null;
    }
    notifyListeners();
  }

  /// Consome o estado terminal atual, voltando para [SingUpState.idle]
  /// **sem** disparar notificação. Usado pela UI para garantir que um
  /// estado terminal seja tratado apenas uma vez (one-shot).
  void consumeState() {
    state = SingUpState.idle;
    errorMessage = null;
  }

  /// Valida se todos os campos obrigatórios estão preenchidos.
  bool get isValid =>
      emailText.text.isNotEmpty &&
      passwordText.text.isNotEmpty &&
      nomeText.text.isNotEmpty;

  /// Cria o usuário no Firebase Auth, persiste dados (usuário adm + PDF),
  /// **salva as credenciais** e popula a sessão exatamente como o login faria.
  ///
  /// A View reage ao [state] — loading/success/error — e não chama nada de UI
  /// daqui. Em `success` a View mostra um SnackBar verde e navega para `/menu`.
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
      // createUserWithEmailAndPassword já autentica o usuário no Firebase.
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

      // Persiste o usuário adm e o PDF padrão.
      await db.saveUserAdm(DADOS);
      await db.savePDF(PDF);

      // Salva as credenciais — mantém a pessoa conectada (auto-login).
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

      // Bate na "rota de login": relê o documento do usuário e a assinatura,
      // deixando a sessão idêntica a um login normal.
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

  /// Relê o documento do usuário em `USUARIOS` e a assinatura vigente,
  /// populando [DADOS] e `globalUIDUser` — réplica do `_getUserInfo` do
  /// [LoginViewModel] para que o pós-cadastro seja idêntico ao pós-login.
  Future<InfoUser> _getUserInfo(String uid) async {
    final snapshot =
        await _firestore
            .collection('USUARIOS')
            .where('USER', isEqualTo: uid)
            .get();

    for (final element in snapshot.docs) {
      final obj = element.data();
      DADOS.USER = obj['USER'];
      DADOS.NOME = obj['NOME'];
      DADOS.EMAIL = obj['EMAIL'];
      DADOS.FONE = obj['FONE'];
      DADOS.Id = obj['Id'];
      DADOS.IdPay = obj['IdPay'];
      DADOS.ProductId = obj['ProductId'];
      DADOS.PurchaseToken = obj['PurchaseToken'];
      DADOS.AutoRenewing = obj['AutoRenewing'] ?? false;

      globalUIDUser.user = obj['USER'];
      globalUIDUser.name = obj['NOME'] ?? 'User';
      globalUIDUser.email = obj['EMAIL'];
      globalUIDUser.phone = obj['FONE'];
      globalUIDUser.id = obj['Id'];
      globalUIDUser.idPay = obj['IdPay'];
      globalUIDUser.productId = obj['ProductId'];
      globalUIDUser.purchaseToken = obj['PurchaseToken'];
      globalUIDUser.autoRenewing = obj['AutoRenewing'] ?? false;
    }

    // Pós-cadastro igual ao pós-login: começa a escutar as notificações de
    // aprovação/reprovação vindas do fluxo Web (push ao dono). Aditivo.
    final ownerUid = globalUIDUser.user;
    if (ownerUid != null && ownerUid.isNotEmpty) {
      // Lista de tokens FCM push do dono (um por dispositivo). Expõe nos
      // "dados do usuário" (`InfoUser.TOKENS` / `global_uid_user.tokens`).
      final tokens =
          await NotificationService.instance.loadFcmTokens(ownerUid);
      DADOS.TOKENS = tokens;
      globalUIDUser.tokens = tokens;
      NotificationService.instance.startBudgetApprovalListener(ownerUid);
    }

    // A consulta de assinaturas (`getAvailablePurchases`) pode falhar
    // (sem Play Services, emulador, rede) exatamente como `fetchProducts`.
    // Isolamos em try/catch para que a falha NUNCA quebre o fluxo de
    // cadastro — o usuário já foi criado/autenticado no Firebase e seu
    // documento já foi lido; a assinatura é complementar.
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

        globalUIDUser.autoRenewing = latestSubscription.isAutoRenewing;
        globalUIDUser.purchaseToken = latestSubscription.purchaseToken ?? '';
        globalUIDUser.productId = latestSubscription.productId;

        if (Platform.isAndroid &&
            latestSubscription is PurchaseAndroid &&
            latestSubscription.isAcknowledgedAndroid != true) {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(
            latestSubscription.purchaseToken ?? '',
          );
        }
      } else {
        globalUIDUser.autoRenewing = false;
        globalUIDUser.purchaseToken = '';
      }
    } catch (_) {
      // Falha ao consultar assinatura não impede o cadastro/login.
      globalUIDUser.autoRenewing = false;
      globalUIDUser.purchaseToken = '';
    }

    return DADOS;
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
