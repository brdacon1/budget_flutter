import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/components/payment_proof_detail_sheet.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/components/payment_proof_tile.dart';
import 'package:oflite/modules/payment_proof/presenter/payment_proof_list/components/payment_proof_total_bar.dart';
import 'package:oflite/modules/invoice/presenter/invoice_list/invoice_list_view_model.dart';
import 'package:oflite/modules/invoice/presenter/strings/invoice_pt_string.dart';
import 'package:oflite/modules/payment_proof/presenter/strings/payment_proof_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:share_plus/share_plus.dart';

/// Tela **Notas fiscais** do orçamento (igual à de comprovantes). Toque abre a
/// imagem em tela cheia ou o PDF no visualizador do app.
class InvoiceListView extends StatefulWidget {
  const InvoiceListView({super.key, required this.item});

  final CustomerInfo item;

  @override
  State<InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<InvoiceListView> {
  late final InvoiceListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = InvoiceListViewModel(item: widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.load());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// A imagem só é baixada aqui (a lista não carrega imagens).
  void _open(Invoice p) => PaymentProofDetailSheet.show(
    context,
    proof: p.toProof(),
    dateTime: _vm.dateTimeOf(p),
    value: _vm.valueOf(p),
    budgetNumber: widget.item.id ?? '',
    clientName: widget.item.customerName ?? '',
  );

  Future<void> _actions(Invoice p) => showModalBottomSheet<void>(
    context: context,
    constraints: const BoxConstraints(maxWidth: appModalMaxWidth),
    backgroundColor: secondaryColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder:
        (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined, color: whiteColor),
                title: Text(
                  PaymentProofStrings.share,
                  style: const TextStyle(color: whiteColor),
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  SharePlus.instance.share(
                    ShareParams(text: '${p.name}\n${p.fileUrl}'),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: statusRejectedColor,
                ),
                title: Text(
                  PaymentProofStrings.delete,
                  style: const TextStyle(color: statusRejectedColor),
                ),
                onTap: () {
                  Navigator.pop(sheet);
                  _confirmDelete(p);
                },
              ),
            ],
          ),
        ),
  );

  Future<void> _confirmDelete(Invoice p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (d) => AlertDialog(
            backgroundColor: secondaryColor,
            content: Text(
              InvoiceStrings.deleteConfirm,
              style: const TextStyle(color: whiteColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: Text(PaymentProofStrings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: Text(
                  PaymentProofStrings.delete,
                  style: const TextStyle(color: statusRejectedColor),
                ),
              ),
            ],
          ),
    );
    if (ok != true) return;
    await _vm.deleteCommand.execute(p);
    if (!mounted) return;
    if (_vm.deleteCommand.error) {
      AlertSnackBar.error(
        context,
        PaymentProofStrings.errorTitle,
        InvoiceStrings.deleteError,
      );
    } else if (_vm.deleteCommand.completed) {
      AlertSnackBar.success(
        context,
        PaymentProofStrings.doneTitle,
        InvoiceStrings.deleteSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: AnimatedBuilder(
        animation: _vm,
        builder:
            (_, __) => PaymentProofTotalBar(
              count: _vm.invoices.length,
              total: _vm.totalText,
              countText: InvoiceStrings.count(_vm.invoices.length),
              counterText: InvoiceStrings.listCounter(_vm.invoices.length),
              totalLabel: InvoiceStrings.totalLabel,
            ),
      ),
      body: AnimatedBuilder(
        animation: _vm,
        builder:
            (context, _) => Column(
              children: [
                AppHeaderSecondTitle(
                  titlePage: InvoiceStrings.menuLabel,
                  secondTitle: InvoiceStrings.listCounter(_vm.invoices.length),
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(child: _body()),
              ],
            ),
      ),
    );
  }

  Widget _body() {
    if (_vm.loading) {
      return const Center(
        child: CircularProgressIndicator(color: loadingIndicatorColor),
      );
    }
    if (_vm.loadError || _vm.invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Text(
          _vm.loadError ? InvoiceStrings.loadError : InvoiceStrings.empty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: emptyTextColor),
        ),
      );
    }
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _vm.load,
      child: AppAdaptiveGrid(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        itemCount: _vm.invoices.length,
        itemBuilder: (_, i) {
          final p = _vm.invoices[i];
          return PaymentProofTile(
            proof: p.toProof(),
            dateTime: _vm.dateTimeOf(p),
            value: _vm.valueOf(p),
            onTap: () => _open(p),
            onMore: () => _actions(p),
          );
        },
      ),
    );
  }
}
