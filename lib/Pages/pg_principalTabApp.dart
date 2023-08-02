import 'package:flutter/material.dart';
import 'package:oflite/Pages/pg_PoupSearch.dart';
import 'package:oflite/Pages/pq_menu.dart';
import 'package:oflite/screens/dashboard/dashboard_screen.dart';
import '../constants.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class pg_PrincipalTabApp extends StatefulWidget {
  @override
  _pg_PrincipalTabAppState createState() => _pg_PrincipalTabAppState();
}

class _pg_PrincipalTabAppState extends State<pg_PrincipalTabApp> {
  int _currentIndex = 0;
  double we = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    we = MediaQuery.of(context).size.width;

    final List<TabItem> tabItems = [
      TabItem(icon: Icons.dashboard, title: 'Dashboard'),
      TabItem(icon: Icons.inventory_outlined, title: 'Orçamentos'),
      TabItem(icon: Icons.menu, title: 'Menu'),
    ];

    final List<Widget> children = [
      const DashboardScreen(),
      pg_PoupSearch(),
      const MenuSelectionPage(),
      // const pg_priceList(fromMenu: true,),
    ];

    return Scaffold(
      body: children[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: secondaryColor, // Define a cor de fundo do BottomNavigationBar
        ),
        child: BottomNavigationBar(
          showUnselectedLabels: true,
          selectedItemColor: Colors.cyan[50],
          selectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
          unselectedItemColor: Colors.grey,
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          items: tabItems
              .map(
                (tabItem) => BottomNavigationBarItem(
              icon: Icon(tabItem.icon),
              label: tabItem.title, // Use a label aqui
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}
