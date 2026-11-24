import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_master_detail.dart';
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
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
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

    final permissionStatus = await user_info.FlutterContacts.permissions
        .request(user_info.PermissionType.readWrite);
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

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: AppFormSaveButton(
        label: _viewModel.nameButton,
        highlighted: _viewModel.isDirty,
        loading: _viewModel.saveBudgetCommand.running,
        onPressed: _onSave,
      ),
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
          // LayoutBuilder: reconstrói quando a área muda com o teclado.
          builder:
              (context, _) => LayoutBuilder(
                builder: (context, _) {
                  // Teclado aberto: esconde botão e mostra a barra de
                  // fechar teclado (§17.8).
                  // Lê do View (não do MediaQuery): a Scaffold das abas já consome o
                  // viewInsets, então MediaQuery aqui sempre retorna 0.
                  final keyboardOpen = View.of(context).viewInsets.bottom > 0;
                  return Column(
                    children: [
                      Expanded(
                        // SafeArea: o conteúdo rolado não passa por baixo da status bar.
                        child: SafeArea(
                          bottom: false,
                          child: AppPageContainer(
                            width: AppPageWidth.wide,
                            child: Stack(
                              children: [
                                ListView(
                                  // Espaço extra no fim para o último campo não ficar sob o
                                  // botão flutuante.
                                  padding: const EdgeInsets.only(bottom: 96),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  children: [
                                    AppHeaderSecondTitle(
                                      showBack:
                                          !AppDetailPane.hidesBackOf(context),
                                      titlePage: _viewModel.titlePage,
                                      secondTitle: 'Dados do cliente',
                                      onBack:
                                          () => Navigator.pop(context, true),
                                      insideSafeArea: true,
                                    ),
                                    if (_viewModel.isEditing)
                                      BudgetCreatorSummaryCard(
                                        viewModel: _viewModel,
                                      ),
                                    BudgetCreatorContactSection(
                                      viewModel: _viewModel,
                                      onPickContact: _viewModel.pickContact,
                                    ),
                                    BudgetCreatorInfoSection(
                                      viewModel: _viewModel,
                                    ),
                                    BudgetCreatorAddressSection(
                                      viewModel: _viewModel,
                                    ),
                                  ],
                                ),
                                if (!keyboardOpen)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: _buildSaveButton(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}
