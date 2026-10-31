import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Fonte externa para Google Mobile Ads.
///
/// Não conhece entidades de negócio; expõe apenas o acesso bruto ao SDK.
class AdsRemoteDataSource {
  Future<void> initialize() => MobileAds.instance.initialize();

  Future<void> setTestDevices(List<String> testDeviceIds) =>
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );

  void loadInterstitial({
    required String adUnitId,
    required void Function(InterstitialAd) onAdLoaded,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
