import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';

/// Biblioteca de comentários com IA: só assinante (`autoRenewing`).
/// Em development, `FORCE_PREMIUM: true` no env libera sem pagamento.
class CheckCommentLibraryAccessUsecase {
  final UserRepository _userRepo;
  final bool Function() _forcePremium;

  CheckCommentLibraryAccessUsecase(
    this._userRepo, {
    bool Function()? forcePremium,
  }) : _forcePremium =
           forcePremium ?? (() => Environment.instance.forcePremium);

  bool call() =>
      _forcePremium() || (_userRepo.selectUser.value?.autoRenewing ?? false);
}
