import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/enums/receipt_field_enum.dart';
import 'package:oflite/common/strings/receipt_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import '../../../../common/constants/constants.dart';

/// Formulário (ExpansionTileCard) de criação/edição de recibo.
///
/// Component `Stateless` puro — recebe os controllers, o estado de seleção de
/// campo, a visibilidade dos campos de número/data e callbacks. **Não**
/// acessa services nem o ViewModel inteiro (segue o padrão do SDD: dados +
/// callbacks).
///
/// Espelha fielmente o layout original da View, inclusive o destaque de campo
/// focado (que usa [selectedField] — visualmente neutro, mas preservado para
/// manter o comportamento original).
class ReceiptCreatorForm extends StatelessWidget {
  const ReceiptCreatorForm({
    super.key,
    required this.descricaoController,
    required this.idController,
    required this.dataController,
    required this.fieldVisible,
    required this.subtitle,
    required this.selectedField,
    required this.onSelectField,
  });

  final TextEditingController descricaoController;
  final TextEditingController idController;
  final TextEditingController dataController;
  final bool fieldVisible;
  final String subtitle;
  final ReceiptFieldType? selectedField;
  final ValueChanged<ReceiptFieldType> onSelectField;

  @override
  Widget build(BuildContext context) {
    final double we = MediaQuery.of(context).size.width;
    final double he = MediaQuery.of(context).size.height;

    // Cores do estado original (ambas brancas → destaque visualmente neutro,
    // preservado para não alterar o comportamento).
    const Color enabledtxt = Colors.white;
    const Color deaible = Colors.white;
    final bool isDescricao = selectedField == ReceiptFieldType.descricao;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.receipt_long_rounded, color: whiteColor),
          ),
          title: Text(
            ReceiptStrings.formCardTitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            Visibility(
              visible: fieldVisible,
              child: FadeAnimationWidget(
                delay: 1,
                child: Container(
                  width: we * 0.8,
                  height: he * 0.078,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: isDescricao ? bgColor : bgColor,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: idController,
                    onTap: () => onSelectField(ReceiptFieldType.descricao),
                    decoration: InputDecoration(
                      enabled: false,
                      enabledBorder: InputBorder.none,
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.confirmation_number_outlined,
                        color: isDescricao ? enabledtxt : deaible,
                      ),
                      hintText: ReceiptStrings.numberHint,
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(
                      color: isDescricao ? enabledtxt : deaible,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: he * 0.02),
            Visibility(
              visible: fieldVisible,
              child: FadeAnimationWidget(
                delay: 1,
                child: Container(
                  width: we * 0.8,
                  height: he * 0.078,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: isDescricao ? bgColor : bgColor,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: dataController,
                    onTap: () => onSelectField(ReceiptFieldType.descricao),
                    decoration: InputDecoration(
                      enabled: false,
                      enabledBorder: InputBorder.none,
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.calendar_month_outlined,
                        color: isDescricao ? enabledtxt : deaible,
                      ),
                      hintText: ReceiptStrings.dateHint,
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: TextStyle(
                      color: isDescricao ? enabledtxt : deaible,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Container(
                width: we * 0.80,
                height: he * 0.075,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: isDescricao ? bgColor : bgColor,
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: descricaoController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 1,
                  onTap: () => onSelectField(ReceiptFieldType.descricao),
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    hintText: ReceiptStrings.descriptionHint,
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(
                    color: isDescricao ? enabledtxt : deaible,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
