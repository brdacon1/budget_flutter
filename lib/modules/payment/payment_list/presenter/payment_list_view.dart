import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'components/payment_list_header.dart';
import 'components/payment_card.dart';
import 'components/payment_total_bar.dart';
import 'payment_list_view_model.dart';

class PaymentListView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt receipt;
  const PaymentListView({
    super.key,
    required this.item,
    required this.receipt,
  });

  @override
  State<PaymentListView> createState() => _PaymentListView();
}

class _PaymentListView extends State<PaymentListView> {
  late final PaymentListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentListViewModel(
      item: widget.item,
      receipt: widget.receipt,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
              PaymentListHeader(onBack: () => Navigator.pop(context, true)),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.cyan[50],
                  backgroundColor: bgColor,
                  onRefresh: _viewModel.refresh,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                        bottom: 150, left: 15, right: 15, top: 10),
                    itemCount: _viewModel.foundPayment.length,
                    itemBuilder: (context, index) {
                      return PaymentCard(
                        item: _viewModel.foundPayment[index],
                        moneyConvert: _viewModel.moneyConvert,
                        onDelete: () =>
                            _viewModel.deletePayment(context, index),
                        onEdit: () =>
                            _viewModel.editPayment(context, index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: buttonColor,
        onPressed: () => _viewModel.addPayment(context),
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
