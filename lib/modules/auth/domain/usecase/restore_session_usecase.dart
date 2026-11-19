import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/auth_repository.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/load_user_session_usecase.dart';
import 'package:oflite/modules/auth/domain/usecase/sign_in_email_usecase.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto-login na abertura: sessão do Firebase ou, sem ela, e-mail/senha
/// salvos.
///
/// Retorna `true` se entrou.
class RestoreSessionUseCase {
  const RestoreSessionUseCase(
    this._authRepository,
    this._userRepository,
    this._loadUserSession,
    this._signInEmail,
  );

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final LoadUserSessionUseCase _loadUserSession;
  final SignInEmailUseCase _signInEmail;

  Future<bool> call({required bool rememberMe}) async {
    final currentUser = await _authRepository.restoreSession();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (currentUser != null) {
      try {
        final isGoogle = password == null || password == 'NO_PASS';
        _userRepository.selectUser.value =
            InfoUser()
              ..user = currentUser.uid
              ..name = currentUser.displayName ?? LoginStrings.userFallback
              ..password = isGoogle ? 'NO_PASS' : password
              ..googleAuth = isGoogle
              ..email = currentUser.email ?? email ?? '';
        await _loadUserSession(currentUser.uid);
        return true;
      } catch (_) {
        return false;
      }
    }

    if (email == null || password == null || password == 'NO_PASS') {
      return false;
    }

    try {
      await _signInEmail(email, password, rememberMe: rememberMe);
      return true;
    } catch (_) {
      return false;
    }
  }
}
