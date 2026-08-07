import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/models/payment_customer.dart';
import 'package:oflite/services/convert_coin.dart';
import '../../../../common/constants/constants.dart';

class PaymentCard extends StatelessWidget {
  final PaymentCustomer item;
  final ConvertCoin moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const PaymentCard({
    Key? key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

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
            item.DESCRICAO!,
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Valor do pagamento: ${moneyConvert.convertFromDouble(item.PRECO!)}",
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(
              thickness: 1.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Método do pagamento: ${item.METODO}",
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
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    onPressed: onDelete,
                  ),
                  _ActionButton(
                    icon: Icons.edit,
                    onPressed: onEdit,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.0,
      height: 52.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 4),
            Icon(icon, color: bgColor),
            const SizedBox(height: 2.0),
            const Text('Editar', style: TextStyle(fontSize: 10, color: bgColor)),
          ],
        ),
      ),
    );
  }
}
