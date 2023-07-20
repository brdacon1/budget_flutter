import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Pages/pg_editPDF.dart';
import 'package:oflite/Pages/pg_priceList.dart';
import 'package:oflite/Services/display_alert.dart';

import '../constants.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MenuSelectionPage extends StatelessWidget {
  final displayAlert = DisplayAlert();
  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: 'Lista de preço'),
    MenuItem(icon: Icons.password, title: 'Trocar de senha'),
    MenuItem(icon: Icons.picture_as_pdf_outlined, title: 'Editar PDF'),
  ];

  MenuSelectionPage({Key? key}) : super(key: key);

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
        displayAlert.dialogChangePassword(context);
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const PgEditPDF()),
        );
        break;
    }
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
                          style: const TextStyle(color: Colors.white),
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
    );
  }
}
