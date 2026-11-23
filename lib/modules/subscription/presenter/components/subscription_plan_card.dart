import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cartão de um plano (mensal/anual) com preço da loja e selo opcional.
class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.label,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;

  /// Preço formatado pela loja.
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? premiumSelectedPlanColor : transparentColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? buttonColor : premiumBorderColor,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: premiumSubtleTextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 19,
                      fontFamily: 'Montserrat-Medium',
                    ),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    color: premiumSubtleTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -9,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: premiumGoldColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: bgColor,
                    fontSize: 10,
                    fontFamily: 'Montserrat-SemiBold',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
