import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/load_user_session_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Login com e-mail e senha. Lança [FirebaseAuthException] em falha.
class SignInEmailUseCase {
  const SignInEmailUseCase(
    this._authRepository,
    this._userRepository,
    this._loadUserSession,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final LoadUserSessionUseCase _loadUserSession;

  Future<void> call(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    final auth = await _authRepository.signInWithEmail(email, password);

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', email);
      await prefs.setString('password', password);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }

    final uid = auth.user!.uid;
    _userRepository.selectUser.value =
        InfoUser()
          ..user = uid
          ..email = email
          ..password = password.trim()
          ..googleAuth = false;

    await _loadUserSession(uid);
  }
}
