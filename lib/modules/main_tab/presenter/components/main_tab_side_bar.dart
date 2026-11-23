import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/main_tab/presenter/components/main_tab_company_logo.dart';
import 'package:oflite/modules/main_tab/presenter/components/main_tab_side_bar_item.dart';
import 'package:oflite/modules/main_tab/presenter/main_tab_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Navegação lateral do app em tela larga (`expanded`). Substitui a bottom
/// navigation, que continua como está no celular (ARCHITECTURE §17.7, §22).
///
/// Componente puro: recebe os itens, o índice atual e o callback.
class MainTabSideBar extends StatelessWidget {
  const MainTabSideBar({
    super.key,
    required this.items,
    this.logo,
    required this.currentIndex,
    required this.onTap,
  });

  /// Largura fixa da barra.
  static const double width = 168;

  /// Logo da empresa (foto do titular); `null` = sem logo.
  final Uint8List? logo;

  final List<TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: secondaryColor,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Center(child: MainTabCompanyLogo(logo: logo)),
              ),
              for (var i = 0; i < items.length; i++)
                MainTabSideBarItem(
                  icon: items[i].icon,
                  title: items[i].title,
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
