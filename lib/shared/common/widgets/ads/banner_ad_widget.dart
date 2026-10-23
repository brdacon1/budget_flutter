import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/shared/common/constants/environment.dart';

/// Widget reutilizável que carrega um banner do AdMob de forma deferida
/// (após a primeira frame pintar) e isola seus rebuilds, evitando que o
/// carregamento do anúncio reconstrua a árvore de widgets da tela inteira.
///
/// Uso:
///   BannerAdWidget(adUnitId: 'ca-app-pub-.../...')
///   // ou como bottomNavigationBar:
///   bottomNavigationBar: BannerAdWidget.banner(...)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.adUnitId,
    this.size = AdSize.banner,
  });

  /// Atalho para uso como bottomNavigationBar, retornando null enquanto
  /// o anúncio não carregou (mantém o comportamento original).
  static Widget? bottom({
    Key? key,
    String? adUnitId,
    AdSize size = AdSize.banner,
  }) {
    return BannerAdWidget(adUnitId: adUnitId, size: size);
  }

  /// ID do bloco de anúncios. Se `null`, utiliza [Environment.adMob.bannerAdUnitId].
  final String? adUnitId;
  final AdSize size;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Deferir o carregamento para depois da primeira frame, evitando
    // travar a pintura inicial da tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _loadAd();
    });
  }

  String get resolvedAdUnitId =>
      widget.adUnitId ?? Environment.instance.adMob.bannerAdUnitId;

  void _loadAd() {
    BannerAd(
      adUnitId: resolvedAdUnitId,
      request: const AdRequest(),
      size: widget.size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          // Loga o motivo da falha para diagnóstico.
          //   0 = ERROR_CODE_INTERNAL_ERROR
          //   1 = ERROR_CODE_INVALID_REQUEST
          //   2 = ERROR_CODE_NETWORK_ERROR
          //   3 = ERROR_CODE_NO_FILL  (sem inventário / não serve em emulador)
          debugPrint(
            '[BannerAdWidget] Falha ao carregar anúncio '
            '(adUnitId=$resolvedAdUnitId, code=${err.code}, message=${err.message}). '
            'Em emulador/dispositivo de dev use o ambiente de desenvolvimento '
            '(test ad unit) ou registre o dispositivo como teste.',
          );
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  @override
  void dispose() {
    _disposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return const SizedBox.shrink();
    }
    final ad = _bannerAd!;
    return SizedBox(
      width: double.infinity,
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
