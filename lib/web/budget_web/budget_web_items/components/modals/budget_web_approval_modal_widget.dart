import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal de aprovação do orçamento Web.
///
/// Reutiliza a base visual `AppBottomModal` (mesmo padrão do app mobile) e
/// os **mesmos valores de status** já usados pelo aplicativo
/// (`APROVADO`/`REPROVADO`). A gravação em si é feita pelo
/// `BudgetWebBudgetViewModel.updateStatus`, que escreve no campo `STATUS`
/// via REST — nenhuma regra de aprovação paralela.
class BudgetWebApprovalModalWidget extends StatelessWidget {
  const BudgetWebApprovalModalWidget({
    super.key,
    required this.onSelect,
  });

  /// Recebe o valor do status selecionado (`APROVADO`/`REPROVADO`).
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: BudgetWebStrings.approvalTitle,
      buttonLabel: '',
      onButtonPressed: () {},
      buttonVisible: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionTile(
              icon: Icons.check_circle_outline,
              label: BudgetWebStrings.statusApproved,
              onTap: () {
                Navigator.of(context).pop();
                onSelect('APROVADO');
              },
            ),
            _OptionTile(
              icon: Icons.highlight_off_outlined,
              label: BudgetWebStrings.statusRejected,
              onTap: () {
                Navigator.of(context).pop();
                onSelect('REPROVADO');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppBottomModal.grayColor),
        title: Text(
          label,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Helper que abre o modal de aprovação.
Future<void> showBudgetWebApprovalModal(
  BuildContext context, {
  required ValueChanged<String> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BudgetWebApprovalModalWidget(onSelect: onSelect),
  );
}
