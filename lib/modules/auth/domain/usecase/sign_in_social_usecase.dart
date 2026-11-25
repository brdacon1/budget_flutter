import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/exception/auth_cancelled_exception.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/load_user_session_usecase.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/domain/usecase/create_sample_product_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Provedor de login social. Não é persistido.
enum SocialProvider { google, apple }

/// Login social: autentica no Firebase, vincula ao usuário existente pelo
/// `uid` e cria os dados padrão se ainda não houver documento.
///
/// Persistência igual ao Google de sempre: senha `NO_PASS` e
/// `googleAuth = true` ("login social, sem senha").
///
/// Lança [AuthCancelledException] quando o usuário fecha o picker.
class SignInSocialUseCase {
  const SignInSocialUseCase(
    this._authRepository,
    this._userRepository,
    this._pdfRepository,
    this._loadUserSession,
    this._createSampleProduct,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final PdfRepository _pdfRepository;
  final LoadUserSessionUseCase _loadUserSession;
  final CreateSampleProductUseCase _createSampleProduct;

  Future<void> call(SocialProvider provider) async {
    final auth = await _authenticate(provider);
    // currentUser já reflete o nome gravado no 1º login com Apple.
    final authUser = _authRepository.currentUser ?? auth.user;
    debugPrint(
      '[SocialLogin] uid=${authUser?.uid} '
      'displayName="${authUser?.displayName}" '
      'credDisplayName="${auth.user?.displayName}"',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', authUser?.email ?? '');
    await prefs.setString('password', 'NO_PASS');

    final uid = authUser?.uid ?? '';
    _userRepository.selectUser.value =
        InfoUser()
          ..user = uid
          ..email = authUser?.email
          ..name = authUser?.displayName ?? LoginStrings.userFallback
          ..password = 'NO_PASS'
          ..googleAuth = true;

    final user = await _loadUserSession(uid);
    debugPrint(
      '[SocialLogin] doc existente=${user != null} nomeNoBanco="${user?.name}"',
    );
    if (user?.user != authUser?.uid) {
      await _createDefaultUser(authUser);
      debugPrint('[SocialLogin] doc criado com nome="${authUser?.displayName}"');
      return;
    }

    // Conta já existia sem nome (ex.: criada antes de a Apple enviar o
    // nome): grava o nome do provedor no banco.
    final providerName = (authUser?.displayName ?? '').trim();
    if (user != null &&
        (user.name ?? '').trim().isEmpty &&
        providerName.isNotEmpty) {
      user.name = providerName;
      await _userRepository.updateUser(user);
      _userRepository.selectUser.value = user;
    }
  }

  Future<UserCredential> _authenticate(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        try {
          return await _authRepository.signInWithGoogle();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled ||
              e.code == GoogleSignInExceptionCode.interrupted) {
            throw AuthCancelledException();
          }
          rethrow;
        }
      case SocialProvider.apple:
        try {
          return await _authRepository.signInWithApple();
        } on SignInWithAppleAuthorizationException catch (e) {
          // Fechar a folha da Apple sem compartilhar pode vir como
          // `unknown` (erro 1000) em vez de `canceled`.
          if (e.code == AuthorizationErrorCode.canceled ||
              e.code == AuthorizationErrorCode.unknown) {
            throw AuthCancelledException();
          }
          rethrow;
        }
    }
  }

  Future<void> _createDefaultUser(User? value) async {
    final infoUser =
        InfoUser()
          ..email = value?.email ?? ''
          ..phone = value?.phoneNumber ?? ''
          ..user = value?.uid ?? ''
          ..name = value?.displayName ?? ''
          ..id = value?.uid ?? '';
    final ownerPdf =
        OwnerPdf()
          ..email = value?.email ?? ''
          ..empresa = LoginStrings.defaultCompanyName
          ..pdfLayoutType = PdfLayoutType.professional.name
          ..logoName = ''
          ..fotoId = '';
    await _userRepository.createDefaultUserData(infoUser, ownerPdf);
    await _pdfRepository.saveInformationEnterprise(ownerPdf);
    // Produto de exemplo na lista de preço; erro não bloqueia o login.
    await _createSampleProduct();
  }
}
