import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Cartão de topo da tela Premium: coroa, título e avaliação.
class SubscriptionHeroCard extends StatelessWidget {
  const SubscriptionHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: premiumCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: premiumGoldColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: bgColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            SubscriptionStrings.heroTitle,
            style: const TextStyle(
              color: whiteColor,
              fontSize: 20,
              fontFamily: 'Montserrat-Bold',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            SubscriptionStrings.heroSubtitle,
            style: const TextStyle(
              color: premiumSubtleTextColor,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'Montserrat-Medium',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: premiumGoldColor, size: 18),
              const SizedBox(width: 6),
              Text(
                SubscriptionStrings.ratingValue,
                style: const TextStyle(color: premiumGoldColor, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text(
                SubscriptionStrings.bestPrice,
                style: const TextStyle(
                  color: premiumSubtleTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
