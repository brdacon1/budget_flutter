/// Contrato do Firebase App Check.
abstract class AppCheckRepository {
  /// Ativa o App Check. Mobile only. Nunca lança — falha só é logada.
  Future<void> initialize();
}
