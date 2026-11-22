import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cabeçalho do modal-lista: handle, título, fechar e busca — mesmo visual
/// do picker da lista de preço, sem filtro de categoria.
class CommentLibraryPickerHeader extends StatelessWidget {
  const CommentLibraryPickerHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClose,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: sheetHandleColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 4, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  CommentLibraryStrings.pickerTitle,
                  style: GoogleFonts.heebo(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: whiteColor, size: 28),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Container(
          height: 50.0,
          margin: const EdgeInsets.only(right: 17.0, left: 17.0, bottom: 18),
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
