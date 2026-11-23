import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/presenter/receipt_payment_list/components/modals/receipt_payment_list_actions_bottom_modal_widget.dart';
import 'package:oflite/modules/receipt/presenter/receipt_payment_list/components/payment_card.dart';
import 'package:oflite/modules/receipt/presenter/receipt_payment_list/components/payment_total_bar.dart';
import 'package:oflite/modules/receipt/presenter/receipt_payment_list/receipt_payment_list_view_model.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

class ReceiptPaymentListView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt receipt;
  final void Function(Receipt)? onReceiptUpdated;

  const ReceiptPaymentListView({
    super.key,
    required this.item,
    required this.receipt,
    this.onReceiptUpdated,
  });

  @override
  State<ReceiptPaymentListView> createState() => _ReceiptPaymentListViewState();
}

class _ReceiptPaymentListViewState extends State<ReceiptPaymentListView> {
  late final ReceiptPaymentListViewModel _viewModel;
  final LoadingEventRepository _loading = getIt<LoadingEventRepository>();
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = ReceiptPaymentListViewModel(
      item: widget.item,
      receipt: widget.receipt,
    );
    _viewModel.deletePaymentCommand.addListener(_deletePaymentCommandChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.inicialData();
    });
  }

  @override
  void dispose() {
    _viewModel.deletePaymentCommand.removeListener(
      _deletePaymentCommandChanged,
    );
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _deletePaymentCommandChanged() async {
    final command = _viewModel.deletePaymentCommand;
    if (command.running) {
      if (mounted) await _loading.alertLoading(context);
      return;
    }
    if (!mounted) return;
    if (command.error) {
      _loading.closeLoading(context);
      await _displayAlert.notificationError(
        context,
        PaymentStrings.errorTitle,
        PaymentStrings.errorRemovePayment,
      );
      await _viewModel.inicialData();
    } else if (command.completed) {
      _loading.closeLoading(context);
      await _displayAlert.notification(
        context,
        PaymentStrings.doneTitle,
        PaymentStrings.paymentRemoved,
      );
      widget.onReceiptUpdated?.call(_viewModel.receipt);
    }
  }

  Future<void> _confirmDelete(int index) async {
    final confirm = await showConfirmBottomModal(
      context,
      title: PaymentStrings.removeTitle,
      message: PaymentStrings.removeMessage,
    );
    if (!confirm || !mounted) return;
    _viewModel.deletePaymentCommand.execute(index);
  }

  Future<void> _edit(int index) async {
    await _viewModel.editPayment(context, index);
    if (mounted) widget.onReceiptUpdated?.call(_viewModel.receipt);
  }

  Future<void> _add() async {
    await _viewModel.addPayment(context);
    if (mounted) widget.onReceiptUpdated?.call(_viewModel.receipt);
  }

  Future<void> _openActions(int index) {
    return showAppModal<void>(
      context,
      isScrollControlled: false,
      builder:
          (_) => ReceiptPaymentListActionsBottomModalWidget(
            item: _viewModel.foundPayment[index],
            moneyConvert: _viewModel.moneyConvert,
            onDelete: () => _confirmDelete(index),
            onEdit: () => _edit(index),
          ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.payments_outlined, color: mutedTextColor, size: 56),
        const SizedBox(height: 12),
        Text(
          PaymentStrings.emptyPaymentsMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.heebo(
            color: whiteColor,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            PaymentStrings.emptyPaymentsSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final items = _viewModel.foundPayment;
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _viewModel.refresh,
      child:
          items.isEmpty
              ? _buildEmpty()
              : AppAdaptiveGrid(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                itemCount: items.length,
                itemBuilder:
                    (context, index) => PaymentCard(
                      item: items[index],
                      moneyConvert: _viewModel.moneyConvert,
                      onTap: () => _openActions(index),
                    ),
              ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      heroTag: 'adicionar_pagamento',
      onPressed: _add,
      backgroundColor: buttonColor,
      icon: const Icon(Icons.add, color: blackColor),
      label: Text(
        PaymentStrings.addPayment,
        style: GoogleFonts.heebo(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final count = _viewModel.foundPayment.length;
        return Scaffold(
          backgroundColor: bgColor,
          body: Column(
            children: <Widget>[
              AppHeaderSecondTitle(
                titlePage: PaymentStrings.paymentsTitle,
                secondTitle:
                    count == 0
                        ? PaymentStrings.paymentsSubtitleEmpty
                        : PaymentStrings.paymentsCount(count),
                onBack: () => Navigator.pop(context, true),
              ),
              Expanded(child: _buildList()),
            ],
          ),
          floatingActionButton: _buildFab(),
          bottomNavigationBar: PaymentTotalBar(
            totalPaid: _viewModel.totalPaid,
            count: count,
            moneyConvert: _viewModel.moneyConvert,
          ),
        );
      },
    );
  }
}
