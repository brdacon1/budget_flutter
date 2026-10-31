/// Contrato para gerenciamento de anúncios AdMob.
///
/// Responsabilidades:
/// - Inicializar o SDK de anúncios (mobile-only).
/// - Carregar e exibir anúncios intersticiais.
/// - Fornecer IDs de blocos de anúncios (banner / interstitial).
abstract class AdsRepository {
  /// Inicializa o SDK do Google Mobile Ads.
  Future<void> initialize();

  /// Configura IDs de dispositivos de teste (development only).
  Future<void> setTestDevices(List<String> testDeviceIds);

  /// Carrega um intersticial (se ainda não estiver carregando/carregado).
  void loadInterstitial();

  /// Exibe o intersticial carregado, se houver.
  void showInterstitial();

  /// Retorna o ID do bloco de banner.
  String get bannerAdUnitId;

  /// Retorna o ID do bloco intersticial.
  String get interstitialAdUnitId;
}
