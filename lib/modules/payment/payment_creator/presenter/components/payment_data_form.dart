import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import '../payment_creator_view_model.dart';

class PaymentDataForm extends StatelessWidget {
  final PaymentCreatorViewModel viewModel;

  const PaymentDataForm({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;

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
            child: Icon(Icons.payments_outlined, color: Colors.white),
          ),
          title: Text(
            "Insira dados do pagamento",
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          subtitle: Text(
            "Clique para ${viewModel.titlePage!.toLowerCase()}",
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.normal,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            FadeAnimationWidget(
              delay: 1,
              child: Container(
                width: we * 0.80,
                height: he * 0.078,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: viewModel.selected == Gender.typeText ? bgColor : bgColor,
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  readOnly: true,
                  enableInteractiveSelection: true,
                  controller: viewModel.typeText,
                  onTap: () => viewModel.selectType(context),
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.list_alt,
                      color: viewModel.selected == Gender.typeText
                          ? viewModel.enabledtxt
                          : viewModel.deaible,
                    ),
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: viewModel.selected == Gender.precoText
                          ? viewModel.enabledtxt
                          : viewModel.deaible,
                    ),
                    hintText: 'Definir pagamento',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(
                    color: viewModel.selected == Gender.typeText
                        ? viewModel.enabledtxt
                        : viewModel.deaible,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: he * 0.02),
            FadeAnimationWidget(
              delay: 1,
              child: Container(
                width: we * 0.80,
                height: he * 0.078,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: viewModel.selected == Gender.precoText ? bgColor : bgColor,
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: viewModel.controller,
                  onTap: () => viewModel.selectField(Gender.precoText),
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.price_change_outlined,
                      color: viewModel.selected == Gender.precoText
                          ? viewModel.enabledtxt
                          : viewModel.deaible,
                    ),
                    hintText: 'Preço',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: viewModel.selected == Gender.precoText
                        ? viewModel.enabledtxt
                        : viewModel.deaible,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Container(
                width: we * 0.80,
                height: he * 0.30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: viewModel.selected == Gender.descricaoText
                      ? bgColor
                      : bgColor,
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: viewModel.descricaoText,
                  keyboardType: TextInputType.multiline,
                  maxLines: 50,
                  onTap: () => viewModel.selectField(Gender.descricaoText),
                  decoration: const InputDecoration(
                    enabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    hintText: 'Escreva a descrição do pagamento...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(
                    color: viewModel.selected == Gender.descricaoText
                        ? viewModel.enabledtxt
                        : viewModel.deaible,
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
