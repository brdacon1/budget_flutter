import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'components/budget_creator_address_section.dart';
import 'components/budget_creator_contact_section.dart';
import 'components/budget_creator_header.dart';
import 'components/budget_creator_info_section.dart';
import 'components/budget_creator_save_button.dart';
import 'budget_creator_view_model.dart';

class BudgetCreatorView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetCreatorView({super.key, required this.item});

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
    final value = await showOptionBottomModal(
      context,
      title: 'Selecione status',
      values: values,
    );
    if (value != null && mounted) {
      _viewModel.setStatus(value);
    }
  }

  Widget _buildBudgetFields({required double height, required double we}) {
    return Expanded(
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
              SizedBox(height: height * 0.20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildButtonSaveBudget({required double we}) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: BudgetCreatorSaveButton(
                  label: _viewModel.nameButton ?? '',
                  onPressed: () async {
                    await _viewModel.eventSave(context, we);
                  },
                ),
              ),
              const SizedBox(height: 10),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          AnimatedBuilder(
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
                  _buildBudgetFields(height: he, we: we),
                ],
              );
            },
          ),
          _buildButtonSaveBudget(we: we),
        ],
      ),
    );
  }
}