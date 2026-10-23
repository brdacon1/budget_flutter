import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior genérico de seleção de uma opção entre uma lista de strings.
///
/// Substitui os antigos `SimpleDialog` + `SimpleDialogOption`. Fundo branco,
/// textos cinza máximo, sem botão de ação (a seleção já fecha o modal).
/// Retorna o valor selecionado via `Navigator.pop(context, value)`.
class OptionBottomModalWidget extends StatelessWidget {
  const OptionBottomModalWidget({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: title,
      buttonLabel: '',
      onButtonPressed: () {},
      buttonVisible: false,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: values.length,
        itemBuilder: (context, index) {
          // Envolve o ListTile num Material próprio para o ink splash ficar
          // visível — o Container branco do AppBottomModal (DecoratedBox)
          // pintaria por cima do splash do Material ancestral sem isto.
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(
                Icons.chevron_right,
                color: AppBottomModal.grayColor,
              ),
              title: Text(
                values[index],
                style: GoogleFonts.heebo(
                  color: AppBottomModal.grayColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.of(context).pop(values[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Helper que abre o [OptionBottomModalWidget] e retorna o valor escolhido.
Future<String?> showOptionBottomModal(
  BuildContext context, {
  required String title,
  required List<String> values,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => OptionBottomModalWidget(
      title: title,
      values: values,
    ),
  );
}
