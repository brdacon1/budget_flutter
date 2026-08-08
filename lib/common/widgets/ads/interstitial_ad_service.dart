import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/common/constants/environment.dart';

/// Serviço singleton para gerenciar um anúncio intersticial compartilhado.
///
/// Carrega o intersticial uma única vez e o recarrega automaticamente quando
/// ele é fechado, evitando recarregar a cada navegação entre telas.
///
/// O [adUnitId] segue o ambiente de build do app (definido em
/// `env/development_environment.json` / `env/production_environment.json` e
/// exposto em [Environment.adMob.interstitialAdUnitId]).
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  /// ID do bloco de anúncios, lido do ambiente (preenchido em
  /// `Environment.instance.initialize()`, aguardado em `main` antes do
  /// `runApp`). As chaves vivem exclusivamente em `env/*.json`.
  String get _adUnitId => Environment.instance.adMob.interstitialAdUnitId;

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
          //   0 = ERROR_CODE_INTERNAL_ERROR
          //   1 = ERROR_CODE_INVALID_REQUEST
          //   2 = ERROR_CODE_NETWORK_ERROR
          //   3 = ERROR_CODE_NO_FILL  (sem inventário / não serve em emulador)
          debugPrint(
            '[InterstitialAdService] Falha ao carregar intersticial '
            '(adUnitId=$_adUnitId, code=${error.code}, message=${error.message}).',
          );
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
