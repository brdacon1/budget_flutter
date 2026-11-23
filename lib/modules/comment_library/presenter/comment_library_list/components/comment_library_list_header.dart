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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                Icons.arrow_back_outlined,
                color: whiteColor,
                size: 35.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 16),
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
        const SizedBox(height: 16),
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
