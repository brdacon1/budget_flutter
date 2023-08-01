import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/Pages/pg_editPDF.dart';
import 'package:oflite/Pages/pg_priceList.dart';
import 'package:oflite/Services/display_alert.dart';

import '../constants.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MenuSelectionPage extends StatefulWidget {

  const MenuSelectionPage({Key? key}) : super(key: key);

  @override
  State<MenuSelectionPage> createState() => _MenuSelectionPage();
}

class _MenuSelectionPage extends State<MenuSelectionPage> {
  final displayAlert = DisplayAlert();
  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: 'Lista de preço'),
    MenuItem(icon: Icons.picture_as_pdf_outlined, title: 'Editar PDF'),
    MenuItem(icon: Icons.person_pin_outlined, title: 'Trocar nome de usuário'),
  ];
  BannerAd? _bannerAd;
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-5106035309089315/6550502888';

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const pg_priceList(fromMenu: true,)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const PgEditPDF()),
        );
        break;
      case 2:
        displayAlert.dialogChangeName(context);
        break;
    }
  }
  void _loadAd() async {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }
  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(height: he * 0.04),
          SizedBox(height: he * 0.03),
          Container(
            margin: const EdgeInsets.only(right: 285.0),
            child: Text(
              "Menu",
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = menuItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                  child: GestureDetector(
                    onTap: () => navigateToPage(context, index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: secondaryColor, width: 2),
                      ),
                      child: ListTile(
                        leading: Icon(menuItem.icon),
                        title: Text(
                          menuItem.title,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.arrow_right),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bannerAd != null
          ? BottomAppBar(color: bgColor,
            height: _bannerAd!.size.height.toDouble(),
            child: SizedBox(height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!),
        ),
      ) : null,
    );
  }
}
