import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Serviço singleton para gerenciar um anúncio intersticial compartilhado.
///
/// Carrega o intersticial uma única vez e o recarrega automaticamente quando
/// ele é fechado, evitando recarregar a cada navegação entre telas.
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  final String _adUnitId = 'ca-app-pub-5106035309089315/6467754164';
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;
  bool _isLoading = false;

  /// Carrega o intersticial caso ainda não esteja carregado.
  void load() {
    if (_interstitialAd != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            load();
          }
        },
      ),
    );
  }

  /// Exibe o intersticial carregado, recarregando em seguida.
  void show() {
    if (_interstitialAd == null) {
      load();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {},
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        load();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _interstitialAd = null;
        load();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
