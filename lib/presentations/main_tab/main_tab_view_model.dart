import 'package:flutter/material.dart';

class TabItem {
  final IconData icon;
  final String title;

  TabItem({required this.icon, required this.title});
}

class MainTabViewModel extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final List<TabItem> _tabItems = [
    TabItem(icon: Icons.dashboard, title: 'Dashboard'),
    TabItem(icon: Icons.inventory_outlined, title: 'Orçamentos'),
    TabItem(icon: Icons.menu, title: 'Menu'),
  ];
  List<TabItem> get tabItems => _tabItems;

  void onTabTapped(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
