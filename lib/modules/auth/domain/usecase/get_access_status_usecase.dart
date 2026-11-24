import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';

/// `premium` = assinante; `trial` = teste grátis ativo; `expired` = acabou.
enum AccessStatus { premium, trial, expired }

/// Única regra de acesso do app: assinante ou teste grátis de 2 dias têm
/// acesso total. Expirado fica em somente leitura (vê e compartilha o que já
/// criou; criar/editar/IA levam à assinatura).
///
/// Sem `trialStartedAt` (offline, conta antiga ainda não sincronizada) o
/// acesso NÃO é bloqueado — nunca travamos o usuário por falha de rede.
class GetAccessStatusUseCase {
  static const trialDuration = Duration(days: 2);

  GetAccessStatusUseCase(this._userRepo, {bool Function()? forcePremium})
    : _forcePremium = forcePremium ?? (() => Environment.instance.forcePremium);

  final UserRepository _userRepo;
  final bool Function() _forcePremium;

  AccessStatus call() {
    final user = _userRepo.selectUser.value;
    if (_forcePremium() || (user?.autoRenewing ?? false)) {
      return AccessStatus.premium;
    }
    final remaining = trialRemaining();
    if (remaining == null || remaining > Duration.zero) {
      return AccessStatus.trial;
    }
    return AccessStatus.expired;
  }

  bool get hasFullAccess => call() != AccessStatus.expired;

  /// Tempo restante do teste (hora do servidor). `null` = sem trial conhecido.
  Duration? trialRemaining() {
    final user = _userRepo.selectUser.value;
    final start = user?.trialStartedAt;
    if (start == null) return null;
    final now = DateTime.now().add(user!.serverClockOffset);
    return start.add(trialDuration).difference(now);
  }
}
