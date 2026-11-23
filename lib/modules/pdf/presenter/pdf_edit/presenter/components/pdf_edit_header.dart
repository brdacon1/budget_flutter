import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class PdfEditHeader extends StatelessWidget {
  final VoidCallback onBack;

  const PdfEditHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.paddingOf(context).top + 16),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: const EdgeInsets.only(left: 16),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 20),
          child: Text(
            PdfStrings.editPdfTitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 20),
          child: Text(
            PdfStrings.pdfInfoTitle,
            style: GoogleFonts.heebo(color: Colors.grey, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
