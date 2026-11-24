import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';

/// Gate do botão "Novo orçamento": assinante e teste grátis passam direto;
/// com o teste expirado abre a assinatura. Retorna `true` se pode criar.
Future<bool> confirmNewBudgetAccess(BuildContext context) async {
  if (getIt<GetAccessStatusUseCase>().hasFullAccess) return true;
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SubscriptionView()),
  );
  return false;
}
