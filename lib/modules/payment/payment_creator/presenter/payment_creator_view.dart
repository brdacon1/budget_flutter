import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'components/payment_creator_header.dart';
import 'components/payment_data_form.dart';
import 'components/payment_save_button.dart';
import 'payment_creator_view_model.dart';

class PaymentCreatorView extends StatefulWidget {
  final PaymentCustomer item;
  const PaymentCreatorView({super.key, required this.item});

  @override
  State<PaymentCreatorView> createState() => _PaymentCreatorView();
}

class _PaymentCreatorView extends State<PaymentCreatorView> {
  final PaymentCreatorViewModel _viewModel = getIt<PaymentCreatorViewModel>();

  @override
  void initState() {
    super.initState();
    _viewModel.init(widget.item);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: SizedBox(
              width: we,
              height: he,
              child: Column(
                children: <Widget>[
                  PaymentCreatorHeader(
                    titlePage: _viewModel.titlePage,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        PaymentDataForm(viewModel: _viewModel),
                        PaymentSaveButton(
                          viewModel: _viewModel,
                          onPressed: () =>
                              _viewModel.save(context, widget.item),
                        ),
                        SizedBox(
                          height: he * 0.3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
