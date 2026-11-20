import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_viewer/payment_proof_viewer_view.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Modal de 80% com o comprovante: imagem no topo (baixada só agora — a
/// lista não carrega imagens para poupar dados) e as informações abaixo.
/// Modal simples, sem VM (§19): só exibe dados prontos.
class PaymentProofDetailSheet extends StatelessWidget {
  const PaymentProofDetailSheet({
    super.key,
    required this.proof,
    required this.dateTime,
    required this.value,
  });

  final PaymentProof proof;
  final String dateTime;
  final String value;

  static Future<void> show(
    BuildContext context, {
    required PaymentProof proof,
    required String dateTime,
    required String value,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: transparentColor,
    builder:
        (sheet) => SizedBox(
          height: MediaQuery.of(sheet).size.height * 0.8,
          child: PaymentProofDetailSheet(
            proof: proof,
            dateTime: dateTime,
            value: value,
          ),
        ),
  );

  bool get _isPdf => proof.type == PaymentProofType.pdf;

  void _openFull(BuildContext context) => PaymentProofViewerView.open(
    context,
    title: proof.name,
    type: proof.type,
    url: proof.fileUrl,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sheetHandleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _preview(context),
                  const SizedBox(height: 20),
                  _row(PaymentProofStrings.detailName, proof.name),
                  _row(PaymentProofStrings.detailValue, value),
                  _row(PaymentProofStrings.detailDate, dateTime),
                  _row(
                    PaymentProofStrings.detailType,
                    _isPdf
                        ? PaymentProofStrings.typePdf
                        : PaymentProofStrings.typeImage,
                  ),
                  if (proof.comment?.isNotEmpty ?? false)
                    _row(PaymentProofStrings.detailComment, proof.comment!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (_isPdf) {
      return Material(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openFull(context),
          child: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 72,
                  color: statusRejectedColor,
                ),
                const SizedBox(height: 10),
                Text(
                  PaymentProofStrings.openPdf,
                  style: const TextStyle(
                    color: buttonColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _openFull(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          child: Image.network(
            proof.fileUrl,
            fit: BoxFit.contain,
            loadingBuilder:
                (_, child, progress) =>
                    progress == null
                        ? child
                        : const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: loadingIndicatorColor,
                            ),
                          ),
                        ),
            errorBuilder:
                (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Icon(
                    Icons.broken_image,
                    color: emptyStateIconColor,
                    size: 56,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: mutedTextColor)),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: whiteColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
