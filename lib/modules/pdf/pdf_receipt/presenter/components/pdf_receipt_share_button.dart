import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class PdfReceiptShareButton extends StatelessWidget {
  final String? filePath;

  const PdfReceiptShareButton({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final enabled = filePath != null;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: FadeAnimationWidget(
          delay: 1,
          child: TextButton(
            onPressed: enabled
                ? () {
                    final xFile = XFile(filePath!);
                    Share.shareXFiles([xFile], text: 'Compartilhar PDF');
                  }
                : null,
            style: TextButton.styleFrom(
                backgroundColor: buttonColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0))),
            child: Text(
              'COMPARTILHAR',
              style: GoogleFonts.heebo(
                color: Colors.black,
                letterSpacing: 0.5,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
