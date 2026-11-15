/// Contrato do serviço de relatório de crashes (Firebase Crashlytics).
abstract class CrashlyticsRepository {
  /// Registra os handlers globais de erro (Flutter + plataforma) e
  /// liga/desliga a coleta conforme o modo de build.
  Future<void> initialize();

  /// Grava um erro não-fatal capturado manualmente (ex.: `catch` em repo).
  Future<void> recordError(Object error, StackTrace? stack);

  /// Vincula os crashes ao usuário logado. `null` desvincula (logout).
  Future<void> setUser(String? uid);
}
