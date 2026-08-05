import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/common/constants/constants.dart';
import 'main_config_menu_view_model.dart';

class MainConfigMenuView extends StatefulWidget {
  const MainConfigMenuView({super.key});

  @override
  State<MainConfigMenuView> createState() => _MainConfigMenuView();
}

class _MainConfigMenuView extends State<MainConfigMenuView> {
  late MainConfigMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MainConfigMenuViewModel();
    _viewModel.loadAd();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
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
                  itemCount: _viewModel.menuItems.length,
                  itemBuilder: (context, index) {
                    final menuItem = _viewModel.menuItems[index];
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                      child: GestureDetector(
                        onTap: () => _viewModel.navigateToPage(context, index),
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
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
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
          bottomNavigationBar: _viewModel.bannerAd != null
              ? SizedBox(
                  width: we,
                  height: _viewModel.bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _viewModel.bannerAd!),
                )
              : null,
        );
      },
    );
  }
}
