import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';

/// Decide se o usuário usa o assistente com IA.
///
/// Mesma regra de premium já usada pelos anúncios (`autoRenewing`).
/// Não-assinante continua no chat determinístico, sem nenhuma mudança.
/// Em development, `FORCE_PREMIUM: true` no env libera sem pagamento.
class CheckAiAccessUsecase {
  /// Kill switch: desliga a IA para todos sem mexer no restante do chat.
  static const aiChatEnabled = true;

  final UserRepository _userRepo;

  final bool Function() _forcePremium;

  CheckAiAccessUsecase(this._userRepo, {bool Function()? forcePremium})
    : _forcePremium = forcePremium ?? (() => Environment.instance.forcePremium);

  bool call() =>
      aiChatEnabled &&
      (_forcePremium() || (_userRepo.selectUser.value?.autoRenewing ?? false));
}
