import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppHeaderSecondTitle extends StatelessWidget {
  const AppHeaderSecondTitle({
    super.key,
    required this.titlePage,
    required this.secondTitle,
    required this.onBack,
    this.isBottomPadding = true,
  });

  final String titlePage;
  final String secondTitle;
  final bool isBottomPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: he * 0.07),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.040),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ),
        SizedBox(height: he * 0.03),
        Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsets.only(left: we * 0.05),
          child: Text(
            titlePage,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          alignment: Alignment.topLeft,
          margin: EdgeInsets.only(left: we * 0.05),
          child: Text(
            secondTitle,
            style: GoogleFonts.heebo(color: Colors.grey, letterSpacing: 1),
          ),
        ),
        isBottomPadding ? SizedBox(height: he * 0.02) : Container(),
      ],
    );
  }
}
