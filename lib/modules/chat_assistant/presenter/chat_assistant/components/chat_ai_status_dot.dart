import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Bolinha colorida do status persistido do orçamento nos cards da IA.
class ChatAiStatusDot extends StatelessWidget {
  final String status;

  const ChatAiStatusDot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: switch (status) {
          'APROVADO' => statusApprovedColor,
          'REPROVADO' => statusRejectedColor,
          'PENDENTE' => statusPendingColor,
          _ => mutedTextColor,
        },
        shape: BoxShape.circle,
      ),
    );
  }
}
