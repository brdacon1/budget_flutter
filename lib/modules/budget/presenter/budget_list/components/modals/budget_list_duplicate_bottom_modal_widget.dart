import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

class BudgetListDuplicateBottomModalWidget extends StatefulWidget {
  const BudgetListDuplicateBottomModalWidget({super.key, required this.onConfirm});

  final Future<void> Function(
    bool clientData,
    bool quoteItems,
    bool comments,
    bool receipts,
  ) onConfirm;

  @override
  State<BudgetListDuplicateBottomModalWidget> createState() =>
      _BudgetListDuplicateBottomModalWidgetState();
}

class _BudgetListDuplicateBottomModalWidgetState
    extends State<BudgetListDuplicateBottomModalWidget> {
  bool duplicateClientData = false;
  bool duplicateQuoteItems = false;
  bool duplicateComments = false;
  bool duplicateReceipts = false;
  bool _processing = false;

  Future<void> _confirm() async {
    if (!duplicateClientData &&
        !duplicateQuoteItems &&
        !duplicateComments &&
        !duplicateReceipts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecione alguma opção')),
      );
      return;
    }
    if (_processing) return;
    setState(() => _processing = true);
    await widget.onConfirm(
      duplicateClientData,
      duplicateQuoteItems,
      duplicateComments,
      duplicateReceipts,
    );
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      scrollable: true,
      title: 'Duplicar orçamento',
      buttonLabel: _processing ? 'Aguarde...' : 'DUPLICAR',
      onButtonPressed: _processing ? () {} : _confirm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CheckTile(
              title: 'Duplicar dados do cliente',
              value: duplicateClientData,
              onChanged: (v) => setState(() => duplicateClientData = v ?? false),
            ),
            _CheckTile(
              title: 'Duplicar itens do orçamento',
              value: duplicateQuoteItems,
              onChanged: (v) => setState(() => duplicateQuoteItems = v ?? false),
            ),
            _CheckTile(
              title: 'Duplicar comentários',
              value: duplicateComments,
              onChanged: (v) => setState(() => duplicateComments = v ?? false),
            ),
            _CheckTile(
              title: 'Duplicar recibos e pagamentos',
              value: duplicateReceipts,
              onChanged: (v) => setState(() => duplicateReceipts = v ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        checkboxShape: const CircleBorder(),
        checkboxScaleFactor: 1.2,
        side: const BorderSide(color: Color(0xFF9E9E9E), width: 1.5),
        checkColor: Colors.white,
        activeColor: AppBottomModal.grayColor,
        title: Text(
          title,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            letterSpacing: 0.5,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
