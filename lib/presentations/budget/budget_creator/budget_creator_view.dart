import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/models/customer_info.dart';
import 'components/budget_creator_address_section.dart';
import 'components/budget_creator_contact_section.dart';
import 'components/budget_creator_header.dart';
import 'components/budget_creator_info_section.dart';
import 'components/budget_creator_save_button.dart';
import 'budget_creator_view_model.dart';

class BudgetCreatorView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetCreatorView({Key? key, required this.item}) : super(key: key);

  @override
  State<BudgetCreatorView> createState() => _BudgetCreatorView();
}

class _BudgetCreatorView extends State<BudgetCreatorView> {
  late final BudgetCreatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetCreatorViewModel(item: widget.item);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectStatus() async {
    List<String> values = ['APROVADO', 'PENDENTE', 'REPROVADO', 'FINALIZADO'];
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          backgroundColor: Colors.cyan[50],
          title: const Text(
            "Selecione status",
            style: TextStyle(color: Colors.black),
          ),
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ListView.builder(
                shrinkWrap: true,
                itemBuilder: (ctx, index) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, values[index]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          values[index],
                          style: const TextStyle(color: bgColor, fontSize: 15.0),
                        ),
                      ],
                    ),
                  );
                },
                itemCount: values.length,
              ),
            )
          ],
        );
      },
    ).then((value) => {
          if (value != null) {_viewModel.setStatus(value)},
        });
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
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              BudgetCreatorHeader(
                titlePage: _viewModel.titlePage ?? '',
                onBack: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    child: Column(
                      children: <Widget>[
                        BudgetCreatorContactSection(
                          viewModel: _viewModel,
                          onPickContact: () =>
                              _viewModel.pickContact(we, context),
                        ),
                        BudgetCreatorInfoSection(
                          viewModel: _viewModel,
                          onSelectStatus: _selectStatus,
                        ),
                        BudgetCreatorAddressSection(
                          viewModel: _viewModel,
                        ),
                        SizedBox(height: he * 0.02),
                        BudgetCreatorSaveButton(
                          label: _viewModel.nameButton ?? '',
                          onPressed: () async {
                            await _viewModel.eventSave(context, we);
                          },
                        ),
                        SizedBox(height: he * 0.10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(
        adUnitId: 'ca-app-pub-5106035309089315/6550502888',
      ),
    );
  }
}
