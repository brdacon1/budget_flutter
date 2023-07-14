import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../anmition/fadeanimation.dart';
import '../constants.dart';

class MenuSelectionPage extends StatelessWidget {
  final List<String> menuItems = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

  MenuSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(mainAxisSize: MainAxisSize.max, children: <Widget>[
        SizedBox(
          height: he * 0.04,
        ),
        SizedBox(
          height: he * 0.03,
        ),
        FadeAnimation(
          delay: 1,
          child: Container(
            margin: const EdgeInsets.only(right: 275.0),
            child: Text(
              "Menu",
              style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  letterSpacing: 2),
            ),
          ),
        ),
        Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = menuItems[index];
                return ListTile(
                  leading: const Icon(Icons.menu),
                  title: Text(menuItem),
                  trailing: const Icon(Icons.arrow_right),
                  onTap: () {
                    print('Item $menuItem clicado!');
                  },
                );
              },
             ),
            ),
        ]
      ),
    );
  }
}
