/// Contrato para gerenciamento de anúncios AdMob.
///
/// Responsabilidades:
/// - Inicializar o SDK de anúncios (mobile-only).
/// - Carregar e exibir anúncios intersticiais.
/// - Fornecer IDs de blocos de anúncios (interstitial).
abstract class AdsRepository {
  /// Inicializa o SDK do Google Mobile Ads.
  Future<void> initialize();

  /// Configura IDs de dispositivos de teste (development only).
  Future<void> setTestDevices(List<String> testDeviceIds);

  /// Carrega um intersticial (se ainda não estiver carregando/carregado).
  void loadInterstitial();

  /// Exibe o intersticial carregado, se houver.
  void showInterstitial();

  /// Exibe o intersticial e completa quando ele é fechado (ou falha /
  /// não está carregado / usuário é assinante). Nunca trava o fluxo.
  Future<void> showInterstitialAndWait();

  /// Retorna o ID do bloco intersticial.
  String get interstitialAdUnitId;

  /// Retorna `true` apenas quando o usuário NÃO é assinante.
  bool get shouldShowAds;
}
