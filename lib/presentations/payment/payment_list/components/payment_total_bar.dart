import 'package:flutter/material.dart';
import 'package:oflite/services/convert_coin.dart';
import '../../../../common/constants/constants.dart';

class PaymentTotalBar extends StatelessWidget {
  final double totalPaid;
  final ConvertCoin moneyConvert;

  const PaymentTotalBar({
    Key? key,
    required this.totalPaid,
    required this.moneyConvert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: buttonColor,
      elevation: 0,
      child: Container(
        height: 65.0,
        color: buttonColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Total pago: ${moneyConvert.convertFromDouble(totalPaid)}",
                style: const TextStyle(
                  color: bgColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
