import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';

/// Gate do botão "Novo orçamento": premium passa direto; os demais veem o
/// anúncio ou vão para a assinatura. Retorna `true` se pode criar.
Future<bool> confirmNewBudgetAccess(BuildContext context) async {
  if (getIt<UserRepository>().selectUser.value?.autoRenewing ?? false) {
    return true;
  }
  final value = await getIt<DisplayAlertRepository>().adsNotification(context);
  if (!context.mounted) return false;
  if (value == "Ver anuncio") {
    getIt<AdsRepository>().showInterstitial();
    return true;
  }
  if (value == "Se tornar premium") {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionView()),
    );
  }
  return false;
}
