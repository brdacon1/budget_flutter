import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_payment_list/budget_payment_list_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_payment_list/components/payment_card.dart';
import 'package:oflite/modules/budget/presenter/budget_payment_list/components/payment_total_bar.dart';
import 'package:oflite/modules/budget/presenter/strings/payment_pt_string.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

class BudgetPaymentListView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt receipt;
  final void Function(Receipt)? onReceiptUpdated;

  const BudgetPaymentListView({
    super.key,
    required this.item,
    required this.receipt,
    this.onReceiptUpdated,
  });

  @override
  State<BudgetPaymentListView> createState() => _BudgetPaymentListViewState();
}

class _BudgetPaymentListViewState extends State<BudgetPaymentListView> {
  late final BudgetPaymentListViewModel _viewModel;
  final LoadingEventRepository alertDisplayLoading =
      getIt<LoadingEventRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetPaymentListViewModel(
      item: widget.item,
      receipt: widget.receipt,
    );
    _viewModel.deletePaymentCommand.addListener(_deletePaymentCommandChanged);
    _viewModel.inicialData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _viewModel.deletePaymentCommand.removeListener(
      _deletePaymentCommandChanged,
    );
    super.dispose();
  }

  Future<void> _deletePaymentCommandChanged() async {
    if (_viewModel.deletePaymentCommand.running) {
      await _openLoad(isOpen: true);
    }

    if (_viewModel.deletePaymentCommand.error) {
      await _openLoad(isOpen: false);
      await _openNotificationNotCloseScreen();
      await _notification(
        isSuccess: false,
        primaryText: PaymentStrings.errorTitle,
        message: PaymentStrings.errorRemovePayment,
      );

      await _viewModel.inicialData();
    } else if (_viewModel.deletePaymentCommand.completed) {
      await _openLoad(isOpen: false);
      await _notification(
        isSuccess: true,
        primaryText: PaymentStrings.doneTitle,
        message: PaymentStrings.paymentRemoved,
      );
      widget.onReceiptUpdated?.call(_viewModel.receipt);
    }
  }

  Future<void> _notification({
    required bool isSuccess,
    required String primaryText,
    required String message,
  }) async {
    if (context.mounted) {
      if (isSuccess) {
        await displayAlert.notification(context, primaryText, message);
      } else {
        await displayAlert.notificationError(context, primaryText, message);
      }
    }
  }

  Future<void> _openLoad({required bool isOpen}) async {
    if (context.mounted) {
      if (isOpen) {
        await alertDisplayLoading.alertLoading(context);
      } else {
        alertDisplayLoading.closeLoading(context);
      }
    }
  }

  Future<void> _openNotificationNotCloseScreen() async {
    await displayAlert.notificationNotCloseScreen(
      context,
      PaymentStrings.doneTitle,
      PaymentStrings.paymentRemoved,
    );
    await _viewModel.inicialData();
  }

  Widget _buildListView() {
    if (_viewModel.foundPayment.isEmpty) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              PaymentStrings.emptyPaymentsMessage,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        color: Colors.cyan[50],
        backgroundColor: bgColor,
        onRefresh: _viewModel.refresh,
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            bottom: 150,
            left: 15,
            right: 15,
            top: 10,
          ),
          itemCount: _viewModel.foundPayment.length,
          itemBuilder: (context, index) {
            return PaymentCard(
              item: _viewModel.foundPayment[index],
              moneyConvert: _viewModel.moneyConvert,
              onDelete: () => _viewModel.deletePaymentCommand.execute(index),
              onEdit: () async {
                await _viewModel.editPayment(context, index);
                if (mounted) widget.onReceiptUpdated?.call(_viewModel.receipt);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              AppHeaderSecondTitle(
                titlePage: PaymentStrings.paymentsTitle,
                secondTitle: 'Pagamentos do orçamento',
                onBack: () => Navigator.pop(context, true),
              ),
              _buildListView(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        onPressed: () async {
          await _viewModel.addPayment(context);
          if (mounted) widget.onReceiptUpdated?.call(_viewModel.receipt);
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return PaymentTotalBar(
            totalPaid: _viewModel.totalPaid,
            moneyConvert: _viewModel.moneyConvert,
          );
        },
      ),
    );
  }
}
