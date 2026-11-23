import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'main_config_menu_view_model.dart';
import 'package:oflite/modules/main_config_menu/presenter/strings/main_config_menu_pt_string.dart';

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
    _viewModel = getIt<MainConfigMenuViewModel>();
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: bgColor,
          body: AppPageContainer(
            width: AppPageWidth.reading,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(height: MediaQuery.paddingOf(context).top + 24),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    MainConfigMenuStrings.pageTitle,
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 15,
                        ),
                        child: GestureDetector(
                          onTap:
                              () => _viewModel.navigateToPage(context, index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: secondaryColor,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(menuItem.icon),
                              title: Text(
                                menuItem.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
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
          ),
        );
      },
    );
  }
}
