import 'package:flutter/material.dart';
import 'package:oflite/presentations/budget/budget_list/budget_list_view.dart';
import 'package:oflite/presentations/main_config_menu/main_config_menu_view.dart';
import 'package:oflite/presentations/dashboard/dashboard_view.dart';
import '../../common/constants/constants.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class MainTabView extends StatefulWidget {
  const MainTabView({Key? key}) : super(key: key);

  @override
  State<MainTabView> createState() => _MainTabView();
}

class _MainTabView extends State<MainTabView> {
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
      const DashboardView(),
      BudgetListView(),
      const MainConfigMenuView(),
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
