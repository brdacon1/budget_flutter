import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/presenter/budget_creator/budget_creator_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_form_field.dart';
import 'package:oflite/shared/common/widgets/form/app_form_section_card.dart';

class BudgetCreatorContactSection extends StatelessWidget {
  const BudgetCreatorContactSection({
    super.key,
    required this.viewModel,
    required this.onPickContact,
  });

  final BudgetCreatorViewModel viewModel;
  final VoidCallback onPickContact;

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      icon: Icons.person_outline,
      title: 'Cliente',
      trailing: TextButton.icon(
        onPressed: onPickContact,
        style: TextButton.styleFrom(
          foregroundColor: buttonColor,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.contacts_outlined, size: 18),
        label: Text(
          viewModel.isEditing ? 'Trocar' : 'Importar da agenda',
          style: GoogleFonts.heebo(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      children: [
        AppFormField(
          label: 'Nome do cliente *',
          hintText: 'Maria Souza',
          prefixIcon: Icons.person_outline,
          controller: viewModel.nameController,
          focusNode: viewModel.nameNode,
          textCapitalization: TextCapitalization.words,
          errorText: viewModel.nameError,
        ),
        const SizedBox(height: 12),
        AppFormField(
          label: 'Telefone',
          hintText: '(11) 98765-4321',
          prefixIcon: Icons.phone_android_outlined,
          controller: viewModel.phoneController,
          focusNode: viewModel.phoneNode,
          keyboardType: TextInputType.phone,
          inputFormatters: [viewModel.maskFormatter],
        ),
      ],
    );
  }
}
