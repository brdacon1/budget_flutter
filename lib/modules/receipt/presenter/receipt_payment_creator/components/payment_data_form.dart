import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import '../receipt_payment_creator_view_model.dart';

class PaymentDataForm extends StatelessWidget {
  final ReceiptPaymentCreatorViewModel viewModel;

  const PaymentDataForm({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          animateTrailing: true,
          trailing: const Icon(Icons.expand_more, color: whiteColor),
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.payments_outlined, color: Colors.white),
          ),
          title: Text(
            PaymentStrings.insertPaymentData,
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
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color:
                    viewModel.selected == Gender.typeText ? bgColor : bgColor,
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
                  prefixIcon: const Icon(Icons.list_alt, color: Colors.white),
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: Colors.white,
                  ),
                  hintText: PaymentStrings.paymentHint,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color:
                    viewModel.selected == Gender.precoText ? bgColor : bgColor,
              ),
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: viewModel.controller,
                onTap: () => viewModel.selectField(Gender.precoText),
                decoration: InputDecoration(
                  enabledBorder: InputBorder.none,
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.price_change_outlined,
                    color: Colors.white,
                  ),
                  hintText: PaymentStrings.priceHint,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color:
                      viewModel.selected == Gender.descricaoText
                          ? bgColor
                          : bgColor,
                ),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: viewModel.descricaoText,
                  keyboardType: TextInputType.multiline,
                  maxLines: 50,
                  onTap: () => viewModel.selectField(Gender.descricaoText),
                  decoration: InputDecoration(
                    enabledBorder: InputBorder.none,
                    border: InputBorder.none,
                    hintText: PaymentStrings.paymentDescriptionHint,
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
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
