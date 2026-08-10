import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/strings/product_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';

/// Cabeçalho da tela de lista de preço: botão voltar + título + campo de
/// busca.
///
/// Component `Stateless` puro — recebe o `TextEditingController` da busca
/// (pertencente ao ViewModel) e callbacks (`onBack`, `onSearchChanged`),
/// sem conhecer o ViewModel nem services. O controller é repassado apenas
/// para o `CupertinoSearchTextField`; a lógica de filtro fica no ViewModel.
class ProductPriceListHeader extends StatelessWidget {
  const ProductPriceListHeader({
    super.key,
    required this.searchController,
    required this.onBack,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: he * 0.07),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            GestureDetector(
              onTap: onBack,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.032),
                child: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: he * 0.02),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.04),
            child: Text(
              ProductStrings.listTitle,
              style: GoogleFonts.heebo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: he * 0.02),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            height: 50.0,
            margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 25),
            child: CupertinoSearchTextField(
              placeholder: ProductStrings.searchHint,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
              backgroundColor: Colors.white12,
              itemColor: whiteColor,
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
        ),
      ],
    );
  }
}
