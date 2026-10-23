import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart';
import 'pdf_edit_field.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class PdfEditEnterpriseCard extends StatelessWidget {
  final TextEditingController nameText;
  final TextEditingController phoneText;
  final TextEditingController emailText;
  final TextEditingController cnpjText;
  final MaskTextInputFormatter maskPhone;
  final MaskTextInputFormatter maskCnpj;
  final Gender? selected;
  final Color enabledColor;
  final Color disabledColor;
  final ValueChanged<Gender> onSelect;

  const PdfEditEnterpriseCard({
    super.key,
    required this.nameText,
    required this.phoneText,
    required this.emailText,
    required this.cnpjText,
    required this.maskPhone,
    required this.maskCnpj,
    required this.selected,
    required this.enabledColor,
    required this.disabledColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.account_balance, color: Colors.white),
          ),
          title: Text(
            "Informações da empresa",
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
              controller: nameText,
              hintText: 'Nome da empresa',
              icon: Icons.account_balance,
              gender: Gender.fullname,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: phoneText,
              hintText: 'Telefone',
              icon: Icons.phone_android_outlined,
              gender: Gender.phone,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              mask: maskPhone,
              keyboardType: TextInputType.number,
              onTap: () => onSelect(Gender.phone),
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: emailText,
              hintText: 'E-mail',
              icon: Icons.email_outlined,
              gender: Gender.email,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              onTap: () => onSelect(Gender.email),
            ),
            const SizedBox(height: 12),
            PdfEditField(
              controller: cnpjText,
              hintText: 'CNPJ',
              icon: Icons.contact_page_outlined,
              gender: Gender.cpf,
              selected: selected,
              enabledColor: enabledColor,
              disabledColor: disabledColor,
              mask: maskCnpj,
              keyboardType: TextInputType.number,
              onTap: () => onSelect(Gender.cpf),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
