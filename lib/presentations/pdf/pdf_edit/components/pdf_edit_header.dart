import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import '../../../../common/constants/constants.dart';

class PdfEditHeader extends StatelessWidget {
  final VoidCallback onBack;

  const PdfEditHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: he * 0.07),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.040),
            child: const Icon(Icons.arrow_back_outlined,
                color: Colors.white, size: 35.0),
          ),
        ),
        SizedBox(height: he * 0.03),
        FadeAnimationWidget(
          delay: 1,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.05),
            child: Text(
              'Editar PDF',
              style: GoogleFonts.heebo(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsets.only(left: we * 0.05),
          child: Text(
            "Informações do PDF",
            style: GoogleFonts.heebo(color: Colors.grey, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
