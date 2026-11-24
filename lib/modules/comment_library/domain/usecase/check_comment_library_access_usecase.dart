import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';

/// Biblioteca de comentários com IA: assinante ou teste grátis ativo.
/// Em development, `FORCE_PREMIUM: true` no env libera sem pagamento.
class CheckCommentLibraryAccessUsecase {
  final GetAccessStatusUseCase _access;

  CheckCommentLibraryAccessUsecase(
    UserRepository userRepo, {
    bool Function()? forcePremium,
  }) : _access = GetAccessStatusUseCase(userRepo, forcePremium: forcePremium);

  bool call() => _access.hasFullAccess;
}
