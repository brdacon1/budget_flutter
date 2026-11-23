import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

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
    this.title,
  });

  final TextEditingController searchController;
  final VoidCallback onBack;
  final ValueChanged<String> onSearchChanged;
  final String? title;

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            GestureDetector(
              onTap: onBack,
              child: Container(
                alignment: Alignment.topLeft,
                margin: const EdgeInsets.only(left: 12),
                child: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 35.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 16),
          child: Text(
            title ?? ProductPtString.listTitle,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 50.0,
          margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 25),
          child: CupertinoSearchTextField(
            placeholder: ProductPtString.searchHint,
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
      ],
    );
  }
}
