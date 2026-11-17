import 'package:material_ui/material_ui.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as user_info;
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/components/budget_creator_address_section.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/components/budget_creator_contact_section.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/components/budget_creator_info_section.dart';
import 'package:oflite/shared/common/widgets/form/app_form_save_button.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/components/budget_creator_summary_card.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/ads/banner_ad_widget.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

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

  void _onSave() {
    FocusScope.of(context).unfocus();
    if (!_viewModel.validate()) return;
    _wasCreating = !_viewModel.isEditing;
    _viewModel.saveBudgetCommand.execute();
  }

  Future<void> _onSaveCommandChanged() async {
    final cmd = _viewModel.saveBudgetCommand;
    if (cmd.running) {
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;

    final alert = getIt<DisplayAlertRepository>();
    if (cmd.error) {
      cmd.clearResult();
      await alert.notificationError(
        context,
        'Não foi possível salvar',
        'Verifique sua conexão e tente novamente.',
      );
      return;
    }
    if (!cmd.completed) return;
    cmd.clearResult();

    if (!_wasCreating) {
      await alert.notificationNotCloseScreen(
        context,
        'Alterações salvas',
        'Dados do orçamento atualizados.',
      );
      return;
    }

    await alert.notification(
      context,
      'Feito!',
      'Orçamento criado. Agora adicione os itens.',
    );
    await _offerSaveContact();
  }

  Future<void> _offerSaveContact() async {
    final phone = _viewModel.phoneController.text;
    if (phone.isEmpty) return;

    final permissionStatus = await user_info.FlutterContacts.permissions.request(
      user_info.PermissionType.readWrite,
    );
    final hasPermission =
        permissionStatus == user_info.PermissionStatus.granted ||
        permissionStatus == user_info.PermissionStatus.limited;
    if (!mounted || !hasPermission) return;

    final saveContact = await showConfirmBottomModal(
      context,
      title: 'Salvar contato',
      message: 'Gostaria de salvar o telefone em sua lista de contatos?',
    );
    if (!saveContact) return;

    await user_info.FlutterContacts.create(
      user_info.Contact(
        name: user_info.Name(first: _viewModel.nameController.text),
        phones: [user_info.Phone(number: phone)],
      ),
    );
  }

  Widget _buildBottomBar() {
    final running = _viewModel.saveBudgetCommand.running;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: AppFormSaveButton(
            label: _viewModel.nameButton,
            highlighted: _viewModel.isDirty,
            loading: running,
            onPressed: _onSave,
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Column(
              children: [
                AppHeaderSecondTitle(
                  titlePage: _viewModel.titlePage,
                  secondTitle: 'Dados do cliente',
                  onBack: () => Navigator.pop(context, true),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      if (_viewModel.isEditing)
                        BudgetCreatorSummaryCard(viewModel: _viewModel),
                      BudgetCreatorContactSection(
                        viewModel: _viewModel,
                        onPickContact: _viewModel.pickContact,
                      ),
                      BudgetCreatorInfoSection(viewModel: _viewModel),
                      BudgetCreatorAddressSection(viewModel: _viewModel),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}
