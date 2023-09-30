import 'dart:convert';
import 'dart:io';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/constants.dart';
import '../anmition/fadeanimation.dart';
import 'utils.dart';
import 'data.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class pg_subscription extends StatefulWidget {
  @override
  _pg_subscription createState() => _pg_subscription();
}

class _pg_subscription extends State<pg_subscription> {
  late List<PurchasedItem>? resultSubscription = [];
  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF696D77), Color(0xFF292C36)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                tileMode: TileMode.clamp)),
        child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: screenAwareSize(20.0, context),
                ),
                onPressed: () async {
                  resultSubscription  = await FlutterInappPurchase.instance.getAvailablePurchases();
                  if(resultSubscription!.isNotEmpty){
                    var latestSubscription = resultSubscription!.reduce((current, next) =>
                    current.transactionDate!.millisecondsSinceEpoch > next.transactionDate!.millisecondsSinceEpoch
                        ? current
                        : next);

                    Map<String, dynamic> data = jsonDecode(latestSubscription.transactionReceipt ?? '');
                    bool acknowledgedValue = data['acknowledged'];
                    UID.AutoRenewing = data['autoRenewing'];
                    UID.PurchaseToken = data['purchaseToken'];
                    UID.ProductId = data['productId'];

                    if(!acknowledgedValue) {
                      await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(latestSubscription.purchaseToken ?? '');
                    }
                  }
                  else
                  {
                    UID.AutoRenewing = false;
                    UID.PurchaseToken = '';
                  }

                  Navigator.pop(context, true);
                },
              ),
              title: Text("Premium",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: screenAwareSize(18.0, context),
                      fontFamily: "Montserrat-Bold")),
              centerTitle: true,

            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ProductScreenTopPart(),
                  ProductScreenBottomPart()
                ],
              ),
            )));
  }
}

class ProductScreenTopPart extends StatefulWidget {
  @override
  _ProductScreenTopPartState createState() => _ProductScreenTopPartState();
}

class _ProductScreenTopPartState extends State<ProductScreenTopPart> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: screenAwareSize(245.0, context),
      child: Stack(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Image.asset("assets/pintor.png",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.none),
            ],
          ),
          Positioned(
            left: screenAwareSize(18.0, context),
            bottom: screenAwareSize(5.0, context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Avaliações",
                    style: TextStyle(
                        color: const Color(0xFF949598),
                        fontSize: screenAwareSize(10.0, context),
                        fontFamily: "Montserrat-SemiBold")),
                SizedBox(
                  height: screenAwareSize(8.0, context),
                ),
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 8.0,
                    ),
                    const Icon(Icons.star, color: Color(0xFFFFE600)),
                    SizedBox(
                      width: screenAwareSize(5.0, context),
                    ),
                    const Text("5.0", style: TextStyle(color: Color(0xFFFFE600))),
                    SizedBox(
                      width: screenAwareSize(5.0, context),
                    ),
                    const Text("Melhor preço",
                        style: TextStyle(color: Colors.white, fontSize: 14.0))
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ProductScreenBottomPart extends StatefulWidget {
  @override
  _ProductScreenBottomPartState createState() =>
      _ProductScreenBottomPartState();
}

class _ProductScreenBottomPartState extends State<ProductScreenBottomPart> {
  bool isExpanded = false;
  int currentSizeIndex = 0;
  int currentColorIndex = 0;
  List<Widget> colorItemList = [];

  final List<String> _productLists = Platform.isAndroid
      ? [
    'newproduct',
  ] : ['com.housestudio.oflite', 'com.housestudio.oflite'];

  @override
  void initState() {
    super.initState();
    asyncInitState(); // async is not allowed on initState() directly
  }

  void asyncInitState() async {
    await FlutterInappPurchase.instance.initialize();
    await FlutterInappPurchase.instance.getSubscriptions(_productLists);
  }

  void _expand() {
    setState(() {
      isExpanded ? isExpanded = false : isExpanded = true;
    });
  }

  List<Widget> colorSelector() {
    for (var i = 0; i < colors.length; i++) {
      colorItemList
          .add(colorItem(colors[i], i == currentColorIndex, context, () {
        setState(() {
          currentColorIndex = i;
        });
      }));
    }
    return colorItemList;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: screenAwareSize(20.0, context)),
            child: Text(
              "Benefícios",
              style: TextStyle(
                  color: const Color(0xFF949598),
                  fontSize: screenAwareSize(12.0, context),
                  fontFamily: "Montserrat-SemiBold"),
            ),
          ),
          SizedBox(
            height: screenAwareSize(8.0, context),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: screenAwareSize(26.0, context),
                right: screenAwareSize(18.0, context)),
            child: AnimatedCrossFade(
              firstChild: Text(
                desc,
                maxLines: 2,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: screenAwareSize(14.0, context),
                    fontFamily: "Montserrat-Medium"),
              ),
              secondChild: Text(
                desc,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: screenAwareSize(14.0, context),
                    fontFamily: "Montserrat-Medium"),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: kThemeAnimationDuration,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: screenAwareSize(26.0, context),
                right: screenAwareSize(18.0, context)),
            child: GestureDetector(
                onTap: _expand,
                child: Text(
                  isExpanded ? "menos" : "mais..",
                  style: const TextStyle(
                      color: Color(0xFFFB382F), fontWeight: FontWeight.w700),
                )),
          ),
          SizedBox(
            height: screenAwareSize(14.0, context),
          ),
          const SizedBox(
            height: 8.0,
          ),
          SizedBox(
            height: screenAwareSize(8.0, context),
          ),
          Padding(
            padding: EdgeInsets.only(left: screenAwareSize(20.0, context)),
            child: const Text("Preço",
                style: TextStyle(
                    color: Color(0xFF949598),
                    fontFamily: "Montserrat-SemiBold")),
          ),
          SizedBox(
            width: double.infinity,
            height: screenAwareSize(120.0, context),
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: screenAwareSize(22.0, context)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenAwareSize(18.0, context)),
                        child: Row(
                          children: <Widget>[
                            Text("R\$ ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenAwareSize(26.0, context),
                                    fontFamily: "Montserrat-Medium")),
                            SizedBox(width: screenAwareSize(2.0, context)),
                            Text("4,99/mês",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenAwareSize(20.0, context),
                                    fontFamily: "Montserrat-Medium"))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: screenAwareSize(15.0, context),
                      ),
                      FadeAnimation(
                        delay: 1,
                        child: TextButton(
                            onPressed: () async {
                              await FlutterInappPurchase.instance.requestSubscription("newproduct");
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 125),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)
                                )
                            ),
                            child: Text("ASSINAR", style: GoogleFonts.heebo(
                              color: Colors.black,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget colorItem(
    Color color, bool isSelected, BuildContext context, VoidCallback _ontab) {
  return GestureDetector(
    onTap: _ontab,
    child: Padding(
      padding: EdgeInsets.only(left: screenAwareSize(10.0, context)),
      child: Container(
        width: screenAwareSize(30.0, context),
        height: screenAwareSize(30.0, context),
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(5.0),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: Colors.black.withOpacity(.8),
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0))
                 ]
                : []),
        child: ClipPath(
          clipper: MClipper(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: color,
          ),
        ),
      ),
    ),
  );
}

class MClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = new Path();

    path.lineTo(0.0, size.height);
    path.lineTo(size.width * 0.2, size.height);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}

