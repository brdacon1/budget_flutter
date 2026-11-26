import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Ícone em caixa + rótulo (atalho da Home).
class HomeQuickActionItem extends StatelessWidget {
  const HomeQuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(13)),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: cardBorderColor),
              ),
              child: Icon(icon, color: buttonColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: mutedTextColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
