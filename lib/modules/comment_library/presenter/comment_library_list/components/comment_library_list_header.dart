import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cabeçalho da biblioteca: voltar + título + busca (mesmo visual da lista
/// de preço).
class CommentLibraryListHeader extends StatelessWidget {
  const CommentLibraryListHeader({
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: he * 0.07),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.only(left: we * 0.032),
              child: const Icon(
                Icons.arrow_back_outlined,
                color: whiteColor,
                size: 35.0,
              ),
            ),
          ),
        ),
        SizedBox(height: he * 0.02),
        Padding(
          padding: EdgeInsets.only(left: we * 0.04),
          child: Text(
            CommentLibraryStrings.listTitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(height: he * 0.02),
        Container(
          height: 50.0,
          margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 25),
          child: CupertinoSearchTextField(
            placeholder: CommentLibraryStrings.searchHint,
            style: const TextStyle(
              color: whiteColor,
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
