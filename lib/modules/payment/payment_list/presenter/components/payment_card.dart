import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/payment/data/model/payment_customer.dart';
import 'package:oflite/modules/payment/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';

class PaymentCard extends StatelessWidget {
  final PaymentCustomer item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PaymentCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.payments_outlined, color: whiteColor),
          ),
          title: Text(
            item.description!,
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            PaymentStrings.paymentValueLabel(
              moneyConvert.convertFromDouble(item.PRECO!),
            ),
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(thickness: 1.0, height: 1.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  PaymentStrings.paymentMethodLabel("${item.METODO}"),
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: PaymentStrings.deleteLabel,
                        onPressed: onDelete,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionButton(
                        icon: Icons.edit,
                        label: PaymentStrings.editLabel,
                        onPressed: onEdit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
