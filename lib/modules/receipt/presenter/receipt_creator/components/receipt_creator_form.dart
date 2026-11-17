import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/widgets/form/app_form_field.dart';
import 'package:oflite/shared/common/widgets/form/app_form_section_card.dart';

/// Formulário de criação/edição de recibo (ARCHITECTURE §17).
///
/// Component `Stateless` puro — recebe controller, erro e callbacks.
/// Nº e data **não** aparecem aqui: no modo editar eles vão para o
/// [ReceiptCreatorSummaryCard] como texto informativo (§17.5).
class ReceiptCreatorForm extends StatelessWidget {
  const ReceiptCreatorForm({
    super.key,
    required this.descricaoController,
    required this.descricaoNode,
    this.descricaoError,
    this.onSubmitted,
  });

  final TextEditingController descricaoController;
  final FocusNode descricaoNode;
  final String? descricaoError;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      icon: Icons.receipt_long_outlined,
      title: ReceiptPtString.formCardTitleSimple,
      children: [
        AppFormField(
          label: ReceiptPtString.descriptionLabel,
          hintText: ReceiptPtString.descriptionExample,
          prefixIcon: Icons.edit_note_outlined,
          controller: descricaoController,
          focusNode: descricaoNode,
          errorText: descricaoError,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
