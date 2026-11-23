import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Benefício curto do plano (ícone + texto) para a grade "Tudo do plano".
class SubscriptionBenefitChip extends StatelessWidget {
  const SubscriptionBenefitChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: premiumCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: buttonColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: premiumBodyTextColor,
                fontSize: 12,
                fontFamily: 'Montserrat-Medium',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
