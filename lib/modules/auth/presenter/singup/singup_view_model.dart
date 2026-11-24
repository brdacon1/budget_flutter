import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/exception/auth_cancelled_exception.dart';
import 'package:oflite/modules/auth/domain/usecase/register_email_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_social_usecase.dart';
import 'package:oflite/modules/auth/presenter/singup/strings/singup_pt_string.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';

enum SingUpState { idle, loading, success, error }

class SingUpViewModel extends ChangeNotifier {
  final RegisterEmailUseCase _registerEmail = getIt<RegisterEmailUseCase>();
  final SignInSocialUseCase _signInSocial = getIt<SignInSocialUseCase>();

  final TextEditingController emailText = TextEditingController();
  final TextEditingController passwordText = TextEditingController();
  final TextEditingController nomeText = TextEditingController();

  bool isPasswordEv = true;

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
    isPasswordEv = !isPasswordEv;
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

  Future<void> register({SocialProvider? linkWith}) async {
    if (!isValid) {
      state = SingUpState.error;
      errorMessage = SingUpStrings.signUpErrorFillAll;
      notifyListeners();
      return;
    }
    await _run(
      () => _registerEmail(
        name: nomeText.text,
        email: emailText.text.trim(),
        password: passwordText.text.trim(),
        linkWith: linkWith,
      ),
    );
  }

  /// Cadastro/entrada só com a rede social (campos vazios).
  Future<void> signUpWithSocial(SocialProvider provider) =>
      _run(() => _signInSocial(provider));

  Future<void> _run(Future<void> Function() action) async {
    state = SingUpState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      state = SingUpState.success;
    } on AuthCancelledException {
      state = SingUpState.idle;
    } on FirebaseAuthException catch (e) {
      state = SingUpState.error;
      errorMessage = _mapFirebaseAuthError(e);
    } catch (_) {
      state = SingUpState.error;
      errorMessage = SingUpStrings.signUpErrorDefault;
    } finally {
      notifyListeners();
    }
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
