import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/load_user_session_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_social_usecase.dart';
import 'package:oflite/modules/auth/presenter/singup/strings/singup_pt_string.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/product/domain/usecase/create_sample_product_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cadastro por e-mail e senha. Com [linkWith], vincula também Google/Apple
/// à MESMA conta (um único `uid`; os dois métodos de entrada funcionam).
///
/// Só a criação da conta e do documento do usuário bloqueiam o cadastro. O
/// resto (PDF, produto de exemplo, sessão) roda em paralelo e uma falha ali
/// nunca derruba o cadastro: o próximo login completa o que faltar.
class RegisterEmailUseCase {
  const RegisterEmailUseCase(
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

  Future<void> call({
    required String name,
    required String email,
    required String password,
    SocialProvider? linkWith,
  }) async {
    final cred = await _authRepository.createUserWithEmail(email, password);
    final uid = cred.user!.uid;

    if (linkWith != null) {
      try {
        await (linkWith == SocialProvider.google
            ? _authRepository.linkWithGoogle()
            : _authRepository.linkWithApple());
      } catch (_) {
        // Cancelou ou a rede social já pertence a outra conta: a conta de
        // e-mail e senha segue válida, o cadastro não falha por isso.
      }
    }

    final infoUser =
        InfoUser()
          ..email = email
          ..phone = ''
          ..user = uid
          ..name = name
          ..id = uid
          ..autoRenewing = false
          ..idPay = ''
          ..productId = ''
          ..purchaseToken = '';
    final ownerPdf =
        OwnerPdf()
          ..email = email
          ..empresa = SingUpStrings.defaultCompanyName
          ..logoName = ''
          ..fotoId = '';

    await _userRepository.createDefaultUserData(infoUser, ownerPdf);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);

    _userRepository.selectUser.value =
        InfoUser()
          ..user = uid
          ..name = name
          ..email = email
          ..phone = infoUser.phone
          ..id = uid
          ..password = password
          ..googleAuth = false
          ..idPay = ''
          ..productId = ''
          ..purchaseToken = ''
          ..autoRenewing = false;

    await Future.wait([
      _safe(() => _pdfRepository.saveInformationEnterprise(ownerPdf)),
      _safe(() => _createSampleProduct()),
      _safe(() => _loadUserSession(uid)),
    ]);
  }

  Future<void> _safe(Future<Object?> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
