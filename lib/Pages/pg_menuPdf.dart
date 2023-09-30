import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/Pages/pg_listComment.dart';
import 'package:oflite/Pages/pg_recivedList.dart';
import 'package:oflite/Services/display_alert.dart';
import '../Objetos/DADOS.dart';
import '../anmition/fadeanimation.dart';
import '../constants.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MenuPagePdf extends StatefulWidget {
  final DADOS item;
  const MenuPagePdf({Key? key, required this.item}) : super(key: key);

  @override
  State<MenuPagePdf> createState() => _MenuSelectionPage();
}

class _MenuSelectionPage extends State<MenuPagePdf> {
  final displayAlert = DisplayAlert();
  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.comment_outlined, title: 'Inserir comentários'),
    MenuItem(icon: Icons.payments_outlined, title: 'Recibo de pagamentos'),
  ];
  BannerAd? _bannerAd;
  final String _adUnitId = 'ca-app-pub-5106035309089315/6550502888';

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ListCommentPage(item: widget.item,)),
        );
        break;
        case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PgRecivedList(item: widget.item)),
        );
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
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(
            height: he * 0.07,
          ),
          GestureDetector(
            onTap: (){
              Navigator.pop(context, true);
            },
            child: Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: we * 0.040),
              child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
            ),
          ),
          SizedBox(
            height: he * 0.03,
          ),
          FadeAnimation(
            delay: 1,
            child: Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: we * 0.05),
              child: Text("Opções",style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: 2
              ),
              ),
            ),
          ),
          Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.05),
            child: Text("Opções do orçamento",style: GoogleFonts.heebo(
                color: Colors.grey,
                letterSpacing: 1),
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
          ? SizedBox(width: we, height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!),
      ) : null,
    );
  }
}
