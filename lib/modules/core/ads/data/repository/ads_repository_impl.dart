import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:oflite/shared/common/constants/environment.dart';

/// Implementação do repositório de anúncios AdMob.
///
/// Mantém um intersticial compartilhado em memória, recarregando
/// automaticamente após ser exibido ou em caso de falha (até 3 tentativas).
class AdsRepositoryImpl implements AdsRepository {
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;
  bool _isLoading = false;

  @override
  String get bannerAdUnitId => Environment.instance.adMob.bannerAdUnitId;

  @override
  String get interstitialAdUnitId =>
      Environment.instance.adMob.interstitialAdUnitId;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<void> setTestDevices(List<String> testDeviceIds) async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }

  @override
  void loadInterstitial() {
    if (_interstitialAd != null || _isLoading) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          debugPrint(
            '[AdsRepositoryImpl] Falha ao carregar intersticial '
            '(adUnitId=$interstitialAdUnitId, code=${error.code}, '
            'message=${error.message}).',
          );
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadInterstitial();
          }
        },
      ),
    );
  }

  @override
  void showInterstitial() {
    if (_interstitialAd == null) {
      debugPrint('[AdsRepositoryImpl] Intersticial não carregado.');
      loadInterstitial();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('[AdsRepositoryImpl] Falha ao exibir: $error');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
