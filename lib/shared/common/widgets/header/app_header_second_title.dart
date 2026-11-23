import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class AppHeaderSecondTitle extends StatelessWidget {
  const AppHeaderSecondTitle({
    super.key,
    required this.titlePage,
    required this.secondTitle,
    required this.onBack,
    this.isBottomPadding = true,
    this.insideSafeArea = false,
  });

  final String titlePage;
  final String secondTitle;
  final bool isBottomPadding;

  /// true quando a tela já tem `SafeArea` no topo: troca o espaço de 7% da
  /// altura (que existe para pular a status bar) por um espaço pequeno.
  final bool insideSafeArea;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: insideSafeArea ? 16 : MediaQuery.paddingOf(context).top + 16),
        GestureDetector(
          onTap: onBack,
          child: Container(
            alignment: Alignment.topLeft,
            margin: const EdgeInsets.only(left: 16),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: whiteColor,
              size: 35.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          alignment: Alignment.topLeft,
          margin: const EdgeInsets.only(left: 20),
          child: Text(
            titlePage,
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
            secondTitle,
            style: GoogleFonts.heebo(color: emptyTextColor, letterSpacing: 1),
          ),
        ),
        isBottomPadding ? const SizedBox(height: 16) : Container(),
      ],
    );
  }
}
