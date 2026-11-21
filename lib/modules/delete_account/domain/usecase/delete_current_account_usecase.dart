import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/delete_account/domain/repository/delete_account_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Exclui a conta do usuário logado no app e encerra os serviços da sessão
/// (listener de aprovações e usuário do Crashlytics).
class DeleteCurrentAccountUsecase {
  DeleteCurrentAccountUsecase(
    this._repository,
    this._notification,
    this._crashlytics,
  );

  final DeleteAccountRepository _repository;
  final NotificationRepository _notification;
  final CrashlyticsRepository _crashlytics;

  Future<Result<void>> call({String? password}) async {
    final result = await _repository.deleteCurrentUser(password: password);
    if (result is Ok<void>) {
      _notification.stopBudgetApprovalListener();
      _crashlytics.setUser(null);
    }
    return result;
  }
}
