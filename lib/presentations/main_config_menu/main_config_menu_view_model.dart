import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/presentations/pdf/pdf_edit/pdf_edit_view.dart';
import 'package:oflite/presentations/product/product_price_list/product_price_list_view.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MainConfigMenuViewModel extends ChangeNotifier {
  final DisplayAlert _displayAlert = DisplayAlert();

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: 'Lista de preço'),
    MenuItem(icon: Icons.picture_as_pdf_outlined, title: 'Editar PDF'),
    MenuItem(icon: Icons.person_pin_outlined, title: 'Trocar nome de usuário'),
  ];

  BannerAd? bannerAd;
  final String adUnitId = 'ca-app-pub-5106035309089315/6550502888';

  void loadAd() {
    BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          bannerAd = ad as BannerAd;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductPriceListView(fromMenu: true),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PdfEditView(),
          ),
        );
        break;
      case 2:
        _displayAlert.dialogChangeName(context);
        break;
    }
  }

  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }
}
