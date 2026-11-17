import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class AppFormSaveButton extends StatelessWidget {
  const AppFormSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.highlighted = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// false = sem alterações pendentes: botão em estilo neutro (§17.5).
  final bool highlighted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: highlighted ? buttonColor : transparentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: highlighted
                ? BorderSide.none
                : const BorderSide(color: sheetHandleColor),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: blackColor),
              )
            : Text(
                label,
                style: GoogleFonts.heebo(
                  color: highlighted ? blackColor : mutedTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
