import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';

class PdfEditSaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PdfEditSaveButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FadeAnimationWidget(
      delay: 1,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          padding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          PdfStrings.updateButton,
          style: GoogleFonts.heebo(
            color: Colors.black,
            letterSpacing: 0.5,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
