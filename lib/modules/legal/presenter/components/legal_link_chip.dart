import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Link para outro documento legal ou idioma.
class LegalLinkChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const LegalLinkChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: buttonColor,
        side: const BorderSide(color: cardBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}
