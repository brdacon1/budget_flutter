import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal inferior com a lista de opções para adicionar orçamento (anúncio).
///
/// Substitui o antigo `SimpleDialog` do `DisplayAlert.adsNotification`. Retorna
/// o valor selecionado via `Navigator.pop(context, value)`. Fundo branco,
/// textos cinza máximo, sem botão de ação (a seleção já fecha o modal).
class AdsOptionBottomModalWidget extends StatelessWidget {
  const AdsOptionBottomModalWidget({super.key});

  static const List<String> _values = ['Ver anuncio', 'Se tornar premium'];

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Escolha uma opção',
      buttonLabel: '',
      onButtonPressed: () {},
      buttonVisible: false,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _values.length,
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: ListTile(
              leading: Icon(
                index == 0 ? Icons.play_circle_outline : Icons.star_outline,
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
