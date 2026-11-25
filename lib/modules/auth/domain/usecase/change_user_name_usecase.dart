import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Troca o nome do usuário logado e sincroniza a sessão em memória.
///
/// Persistência inalterada: grava o mesmo conjunto de campos de `USUARIOS`
/// (via [UserRepository.updateUser]), só com `NOME` novo.
class ChangeUserNameUseCase {
  const ChangeUserNameUseCase(this._userRepository);

  final UserRepository _userRepository;

  Future<Result<void>> call(String name) {
    final session = _userRepository.selectUser.value ?? InfoUser();
    final updated =
        InfoUser()
          ..autoRenewing = session.autoRenewing
          ..email = session.email
          ..phone = session.phone
          ..id = session.id
          ..idPay = session.idPay
          ..name = name
          ..productId = session.productId
          ..purchaseToken = session.purchaseToken
          ..user = session.user
          // Campos só de sessão: o repository troca `selectUser` por este
          // objeto, então precisam ser preservados.
          ..password = session.password
          ..googleAuth = session.googleAuth
          ..trialStartedAt = session.trialStartedAt
          ..serverClockOffset = session.serverClockOffset
          ..tokens = session.tokens;
    return _userRepository.updateUser(updated);
  }
}
