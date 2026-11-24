import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';

/// Decide se o usuário usa o assistente com IA: assinante ou teste grátis
/// ativo ([GetAccessStatusUseCase]). Expirado continua no chat determinístico.
/// Em development, `FORCE_PREMIUM: true` no env libera sem pagamento.
class CheckAiAccessUsecase {
  /// Kill switch: desliga a IA para todos sem mexer no restante do chat.
  static const aiChatEnabled = true;

  final GetAccessStatusUseCase _access;

  CheckAiAccessUsecase(UserRepository userRepo, {bool Function()? forcePremium})
    : _access = GetAccessStatusUseCase(userRepo, forcePremium: forcePremium);

  bool call() => aiChatEnabled && _access.hasFullAccess;
}
