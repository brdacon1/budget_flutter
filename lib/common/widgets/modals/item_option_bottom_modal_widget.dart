import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior com a lista de opções para inserir item no orçamento.
///
/// Substitui o antigo `SimpleDialog` do `DisplayAlert.listNotification`.
/// Retorna o valor selecionado via `Navigator.pop(context, value)`. Fundo
/// branco, textos cinza máximo, sem botão de ação (a seleção já fecha).
class ItemOptionBottomModalWidget extends StatelessWidget {
  const ItemOptionBottomModalWidget({super.key});

  static const List<String> _values = [
    'Criar novo item',
    'Selecionar da lista de preço',
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Como você quer inserir o item?',
      buttonLabel: '',
      onButtonPressed: () {},
      buttonVisible: false,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _values.length,
        itemBuilder: (context, index) {
          // Envolve o ListTile num Material próprio para o ink splash ficar
          // visível — o Container branco do AppBottomModal (DecoratedBox)
          // pintaria por cima do splash do Material ancestral sem isto.
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(
                index == 0 ? Icons.add_circle_outline : Icons.list_alt,
                color: AppBottomModal.grayColor,
              ),
              title: Text(
                _values[index],
                style: GoogleFonts.heebo(
                  color: AppBottomModal.grayColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.of(context).pop(_values[index]),
            ),
          );
        },
      ),
    );
  }
}
