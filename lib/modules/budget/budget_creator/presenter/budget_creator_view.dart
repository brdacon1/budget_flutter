import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as user_info;
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';

import '../../../../shared/common/widgets/header/app_header_second_title.dart';
import 'budget_creator_view_model.dart';
import 'components/budget_creator_address_section.dart';
import 'components/budget_creator_contact_section.dart';
import 'components/budget_creator_info_section.dart';
import 'components/budget_creator_save_button.dart';

class BudgetCreatorView extends StatefulWidget {
  final CustomerInfo item;

  const BudgetCreatorView({super.key, required this.item});

  @override
  State<BudgetCreatorView> createState() => _BudgetCreatorView();
}

class _BudgetCreatorView extends State<BudgetCreatorView> {
  late final BudgetCreatorViewModel _viewModel;
  bool _wasCreating = false;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetCreatorViewModel(item: widget.item);
    _viewModel.saveBudgetCommand.addListener(_onSaveCommandChanged);
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.saveBudgetCommand.removeListener(_onSaveCommandChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onSaveCommandChanged() async {
    final cmd = _viewModel.saveBudgetCommand;

    if (cmd.running) {
      setState(() {});
      return;
    }

    if (!cmd.completed) return;

    cmd.clearResult();

    if (!_wasCreating) {
      if (mounted) {
        await getIt<DisplayAlertRepository>().notification(
          context,
          'Feito!',
          'Dados do orçamento atualizado com sucesso!',
        );
      }
      return;
    }

    if (mounted) {
      await getIt<DisplayAlertRepository>().notification(
        context,
        'Feito!',
        'Orçamento criado com sucesso!',
      );
    }

    if (mounted && await user_info.FlutterContacts.requestPermission()) {
      if (mounted) {
        final saveContact = await showConfirmBottomModal(
          context,
          title: 'Salvar contato',
          message: 'Gostaria de salvar o telefone em sua lista de contatos?',
        );
        if (saveContact) {
          final newContact =
              user_info.Contact()
                ..name = Name(first: _viewModel.nameController.text)
                ..phones = [
                  Phone(_viewModel.phoneController.text),
                  Phone(
                    _viewModel.phoneController.text,
                    label: PhoneLabel.work,
                  ),
                ];
          await user_info.FlutterContacts.insertContact(newContact);
        }
      }
    }
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
                onPickContact: () => _viewModel.pickContact(we, context),
              ),
              BudgetCreatorInfoSection(
                viewModel: _viewModel,
                onSelectStatus: _selectStatus,
              ),
              BudgetCreatorAddressSection(viewModel: _viewModel),
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
                  onPressed:
                      _viewModel.saveBudgetCommand.running
                          ? null
                          : () {
                            _wasCreating = !_viewModel.isEditing;
                            _viewModel.saveBudgetCommand.execute();
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

  Widget _buildScreen({required double height, required double we}) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            AppHeaderSecondTitle(
              titlePage: _viewModel.titlePage ?? '',
              secondTitle: 'Informações do orçamento',
              onBack: () => Navigator.pop(context, true),
            ),
            _buildBudgetFields(height: height, we: we),
          ],
        );
      },
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
          _buildScreen(height: he, we: he),
          _buildButtonSaveBudget(we: we),
        ],
      ),
    );
  }
}
