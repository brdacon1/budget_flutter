import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;
import 'package:oflite/shared/common/constants/constants.dart';
import 'components/pdf_edit_header.dart';
import 'components/pdf_edit_logo_section.dart';
import 'components/pdf_edit_enterprise_card.dart';
import 'components/pdf_edit_address_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          return Column(
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
                        autoRenewing: UID.autoRenewing ?? false,
                        onEditLogo: () => vm.editLogo(context),
                        onOpenSubscription: () =>
                            vm.openSubscription(context),
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
                      SizedBox(height: he * 0.02),
                      PdfEditSaveButton(onPressed: () => vm.save(context)),
                      SizedBox(height: he * 0.10),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
