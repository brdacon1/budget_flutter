import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card do comprovante (mesmo padrão do card de orçamento/recibo):
/// nome, data e hora do salvamento, comentário, valor e tipo.
class PaymentProofTile extends StatelessWidget {
  const PaymentProofTile({
    super.key,
    required this.proof,
    required this.dateTime,
    required this.value,
    required this.onTap,
    required this.onMore,
  });

  final PaymentProof proof;
  final String dateTime;
  final String value;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final isPdf = proof.type == PaymentProofType.pdf;
    final accent = isPdf ? statusRejectedColor : buttonColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onMore,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 13, 4, 13),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proof.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateTime,
                        style: const TextStyle(color: whiteColor, fontSize: 12),
                      ),
                      if (proof.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          proof.comment!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: mutedTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: proof.value == null ? mutedTextColor : whiteColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPdf
                            ? PaymentProofStrings.typePdf
                            : PaymentProofStrings.typeImage,
                        style: TextStyle(color: accent, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onMore,
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
