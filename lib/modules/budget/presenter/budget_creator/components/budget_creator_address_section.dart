import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_form_field.dart';
import 'package:oflite/shared/common/widgets/form/app_form_section_card.dart';

class BudgetCreatorAddressSection extends StatelessWidget {
  const BudgetCreatorAddressSection({super.key, required this.viewModel});

  final BudgetCreatorViewModel viewModel;

  Widget? _cepSuffix() {
    switch (viewModel.cepState) {
      case CepLookupState.loading:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: buttonColor,
            ),
          ),
        );
      case CepLookupState.found:
        return const Icon(
          Icons.check_circle_outline,
          color: statusApprovedColor,
        );
      case CepLookupState.notFound:
        return const Icon(Icons.error_outline, color: statusRejectedColor);
      case CepLookupState.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      icon: Icons.location_on_outlined,
      title: 'Endereço',
      trailing: Text(
        'opcional',
        style: GoogleFonts.heebo(color: mutedTextColor, fontSize: 12),
      ),
      children: [
        AppFormField(
          label: 'CEP',
          hintText: '00000-000',
          prefixIcon: Icons.search,
          controller: viewModel.cepController,
          focusNode: viewModel.cepNode,
          keyboardType: TextInputType.number,
          inputFormatters: [viewModel.maskCep],
          onChanged: viewModel.onCepChanged,
          suffix: _cepSuffix(),
        ),
        if (viewModel.cepState == CepLookupState.notFound)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              'CEP não encontrado. Preencha o endereço abaixo.',
              style: GoogleFonts.heebo(
                color: statusRejectedColor,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        AppFormField(
          label: 'Rua',
          prefixIcon: Icons.signpost_outlined,
          controller: viewModel.ruaController,
          focusNode: viewModel.ruaNode,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        AppFormField(
          label: 'Bairro',
          prefixIcon: Icons.holiday_village_outlined,
          controller: viewModel.bairroController,
          focusNode: viewModel.bairroNode,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        AppFormField(
          label: 'Cidade',
          prefixIcon: Icons.location_city_outlined,
          controller: viewModel.cityController,
          focusNode: viewModel.cityNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
