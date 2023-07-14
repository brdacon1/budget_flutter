import 'package:flutter/material.dart';
import 'package:oflite/Pages/pg_PoupSearch.dart';
import 'package:oflite/Pages/pg_priceList.dart';
import 'package:oflite/Pages/pq_menu.dart';
import 'package:oflite/screens/dashboard/dashboard_screen.dart';
import '../constants.dart';


class pg_PrincipalTabApp extends StatefulWidget {
  @override
  _pg_PrincipalTabApp createState() => _pg_PrincipalTabApp();
}

class _pg_PrincipalTabApp extends State<pg_PrincipalTabApp> {
  int _currentIndex = 0;
  double we = 0;

  void onTabTapped(int index) {
    setState(() {
      if(index == 0) {
        _currentIndex = index;
      }
      else {
        _currentIndex = index;
      }
    });
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;
    final List children = [
       const DashboardScreen(),
       pg_PoupSearch(),
       MenuSelectionPage(),
       //const pg_priceList(fromMenu: true,),
    ];
    return Scaffold(
      body: children[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: secondaryColor, // Define a cor de fundo do BottomNavigationBar
        ),
        child: BottomNavigationBar(
          selectedItemColor: Colors.cyan[50],
          selectedLabelStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          unselectedItemColor: Colors.grey,
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Orçamentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}



