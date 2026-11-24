import 'dart:io';

import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';
import 'package:oflite/modules/core/in_app_purchase/domain/repository/in_app_purchase_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Carrega o usuário do Firestore para a sessão já iniciada em
/// `selectUser` e liga FCM, listener de orçamentos, Crashlytics e assinatura.
///
/// Retorna o usuário do Firestore, ou `null` se ainda não houver documento.
class LoadUserSessionUseCase {
  const LoadUserSessionUseCase(
    this._userRepository,
    this._notificationRepository,
    this._crashlyticsRepository,
    this._inAppPurchaseRepository,
  );

  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final CrashlyticsRepository _crashlyticsRepository;
  final InAppPurchaseRepository _inAppPurchaseRepository;

  Future<InfoUser?> call(String uid) async {
    final result = await _userRepository.getUserInfo(uid);
    if (result is! Ok<InfoUser?>) return null;

    final user = result.value;
    if (user != null) {
      // Preserva Senha e googleAuth que nunca vêm do Firestore
      final prev = _userRepository.selectUser.value;
      if (prev != null) {
        user.password = prev.password;
        user.googleAuth = prev.googleAuth;
      }
      _userRepository.selectUser.value = user;
    }

    final ownerUid = _userRepository.selectUser.value?.user;
    if (ownerUid != null && ownerUid.isNotEmpty) {
      final tokens = await _notificationRepository.loadFcmTokens(ownerUid);
      user?.tokens = tokens;
      _notificationRepository.startBudgetApprovalListener(ownerUid);
      _crashlyticsRepository.setUser(ownerUid);
    }
    _notificationRepository.tryOpenPendingBudget();

    await _userRepository.syncTrial(uid);
    await _loadSubscription();
    return user;
  }

  Future<void> _loadSubscription() async {
    final session = _userRepository.selectUser.value ?? InfoUser();
    try {
      final purchases = await _inAppPurchaseRepository.getAvailablePurchases();
      if (purchases.isEmpty) {
        session.autoRenewing = false;
        session.purchaseToken = '';
      } else {
        final latest = purchases.reduce(
          (current, next) =>
              current.transactionDate > next.transactionDate ? current : next,
        );
        session.autoRenewing = latest.isAutoRenewing;
        session.purchaseToken = latest.purchaseToken;
        session.productId = latest.productId;

        if (Platform.isAndroid && latest.needsCompletion) {
          await _inAppPurchaseRepository.acknowledgePurchaseAndroid(latest);
        }
      }
    } catch (_) {
      session.autoRenewing = false;
      session.purchaseToken = '';
    }
    _userRepository.selectUser.value = session;
  }
}
