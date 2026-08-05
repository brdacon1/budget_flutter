import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/presentations/comment/comment_list_view.dart';
import 'package:oflite/presentations/receipt/receipt_list/receipt_list_view.dart';
import 'package:oflite/Services/display_alert.dart';
import '../../../models/customer_info.dart';
import '../../../common/constants/constants.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class PdfMenuView extends StatefulWidget {
  final CustomerInfo item;
  const PdfMenuView({Key? key, required this.item}) : super(key: key);

  @override
  State<PdfMenuView> createState() => _PdfMenuView();
}

class _PdfMenuView extends State<PdfMenuView> {
  final displayAlert = DisplayAlert();
  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.comment_outlined, title: 'Inserir comentários'),
    MenuItem(icon: Icons.payments_outlined, title: 'Recibo de pagamentos'),
  ];

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CommentListView(item: widget.item,)),
        );
        break;
        case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ReceiptListView(item: widget.item)),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
          FadeAnimationWidget(
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
      bottomNavigationBar: const BannerAdWidget(
        adUnitId: 'ca-app-pub-5106035309089315/6550502888',
      ),
    );
  }
}
