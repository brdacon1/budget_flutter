import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class ExpansionCardLabel extends StatelessWidget {
  const ExpansionCardLabel({
    super.key,
    required this.nameText,
    required this.textData,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  final String nameText;
  final String textData;

  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
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
      ),
    );
  }
}
