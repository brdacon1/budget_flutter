import 'package:oflite/shared/common/constants/environment.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import 'components/pdf_edit_address_card.dart';
import 'components/pdf_edit_enterprise_card.dart';
import 'components/pdf_edit_header.dart';
import 'components/pdf_edit_logo_section.dart';
import 'components/pdf_edit_save_button.dart';
import 'pdf_edit_view_model.dart';

class PdfEditView extends StatefulWidget {
  const PdfEditView({super.key});

  @override
  State<PdfEditView> createState() => _PdfEditView();
}

class _PdfEditView extends State<PdfEditView> {
  late final PdfEditViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<PdfEditViewModel>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
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
          final vm = _viewModel;
          return AppPageContainer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                PdfEditHeader(onBack: () => Navigator.pop(context, true)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        PdfEditLogoSection(
                          fileContent: vm.fileContent,
                          loading: vm.loading,
                          hasError: vm.hasError,
                          autoRenewing:
                              Environment.instance.forcePremium ||
                              (getIt<UserRepository>()
                                      .selectUser
                                      .value
                                      ?.autoRenewing ??
                                  false),
                          onEditLogo: () => vm.editLogo(context),
                          onOpenSubscription:
                              () => vm.openSubscription(context),
                        ),
                        PdfEditEnterpriseCard(
                          nameText: vm.nameText,
                          phoneText: vm.phoneText,
                          emailText: vm.emailText,
                          cnpjText: vm.cpfText,
                          maskPhone: vm.maskPhone,
                          maskCnpj: vm.maskCnpj,
                          selected: vm.selected,
                          enabledColor: vm.enabledtxt,
                          disabledColor: vm.deaible,
                          onSelect: vm.selectField,
                        ),
                        PdfEditAddressCard(
                          cepText: vm.cepText,
                          ruaText: vm.ruaText,
                          cityText: vm.cityText,
                          bairroText: vm.bairroText,
                          maskCep: vm.maskCep,
                          selected: vm.selected,
                          enabledColor: vm.enabledtxt,
                          disabledColor: vm.deaible,
                          onSelect: vm.selectField,
                          onCepChanged: vm.lookupCep,
                        ),
                        const SizedBox(height: 16),
                        PdfEditSaveButton(onPressed: () => vm.save(context)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
