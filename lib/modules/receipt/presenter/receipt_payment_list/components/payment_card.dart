import 'package:oflite/modules/receipt/domain/entity/payment_method.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card compacto do pagamento. Toque ou "⋮" abrem as ações.
class PaymentCard extends StatelessWidget {
  final PaymentCustomer item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onTap;

  const PaymentCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: buttonColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.heebo(
                          color: whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              PaymentMethod.labelOf(item.method),
                              style: GoogleFonts.heebo(
                                color: mutedTextColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            moneyConvert.convertFromDouble(item.price ?? 0),
                            style: GoogleFonts.heebo(
                              color: whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.more_vert, color: mutedTextColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
