import 'package:get_it/get_it.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';
import 'package:oflite/modules/core/services/data/service/notification_service.dart';
import 'package:oflite/modules/core/services/data/service/via_cep_service.dart';

/// Registra os serviços compartilhados do módulo Core.
///
/// São helpers stateless ou de uso global (formatação, loading, alertas,
/// notificações, CEP, etc.). Mantidos como `LazySingleton` pois são
/// custosos de recriar ou devem ser únicos na aplicação.
///
/// `BudgetShareLinkService` não consta aqui porque é puramente estático
/// (métodos e `const` — nunca é instanciado).
///
/// **TODO futuro:**
/// - Extrair abstrações (interfaces) de `DisplayAlert` e `NotificationService`
///   para permitir mocks em testes unitários sem depender do Flutter/Firebase
///   real.
void registerCoreDependencies(GetIt sl) {
  sl.registerLazySingleton<ConvertCoin>(() => ConvertCoin());
  sl.registerLazySingleton<LoadingEvent>(() => LoadingEvent());
  sl.registerLazySingleton<DisplayAlert>(() => DisplayAlert());
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService.instance,
  );
  sl.registerLazySingleton<ViaCepService>(() => ViaCepService());
}
