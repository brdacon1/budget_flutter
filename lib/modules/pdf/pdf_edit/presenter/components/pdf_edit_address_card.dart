import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart';
import 'pdf_edit_field.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class PdfEditAddressCard extends StatelessWidget {
  final TextEditingController cepText;
  final TextEditingController ruaText;
  final TextEditingController cityText;
  final TextEditingController bairroText;
  final MaskTextInputFormatter maskCep;
  final Gender? selected;
  final Color enabledColor;
  final Color disabledColor;
  final ValueChanged<Gender> onSelect;
  final ValueChanged<String> onCepChanged;

  const PdfEditAddressCard({
    super.key,
    required this.cepText,
    required this.ruaText,
    required this.cityText,
    required this.bairroText,
    required this.maskCep,
    required this.selected,
    required this.enabledColor,
    required this.disabledColor,
    required this.onSelect,
    required this.onCepChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.location_on_outlined, color: whiteColor),
          ),
          title: Text(
            "Informações de endereço",
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          subtitle: Text(
            "Clique para editar",
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            PdfEditField(
              controller: cepText,
              hintText: 'CEP',
              icon: Icons.add_location_outlined,
              gender: Gender.cep,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              mask: maskCep,
              keyboardType: TextInputType.number,
              onTap: () => onSelect(Gender.cep),
              onChanged: onCepChanged,
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: ruaText,
              hintText: 'Rua',
              icon: Icons.location_on_outlined,
              gender: Gender.rua,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              onTap: () => onSelect(Gender.rua),
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: cityText,
              hintText: 'Cidade',
              icon: Icons.location_city_outlined,
              gender: Gender.city,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              onTap: () => onSelect(Gender.city),
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: bairroText,
              hintText: 'Bairro',
              icon: Icons.location_searching,
              gender: Gender.bairro,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              onTap: () => onSelect(Gender.bairro),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
