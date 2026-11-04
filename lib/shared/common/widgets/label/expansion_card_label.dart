import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class ExpansionCardLabel extends StatelessWidget {
  const ExpansionCardLabel({
    super.key,
    required this.nameText,
    required this.textData,
  });

  final String nameText;
  final String textData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          nameText,
          style: const TextStyle(
            color: whiteColor,
            letterSpacing: 0.5,
            fontSize: 12.0,
          ),
        ),
        Text(
          textData,
          style: const TextStyle(
            color: whiteColor,
            letterSpacing: 0.5,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}
