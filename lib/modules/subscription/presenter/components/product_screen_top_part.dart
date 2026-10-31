import 'package:flutter/material.dart';
import 'package:oflite/shared/common/utils/height_calculate_utils.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';

class ProductScreenTopPart extends StatelessWidget {
  const ProductScreenTopPart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: screenAwareSize(245.0, context),
      child: Stack(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Image.asset(
                "assets/pintor.png",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.none,
              ),
            ],
          ),
          Positioned(
            left: screenAwareSize(18.0, context),
            bottom: screenAwareSize(5.0, context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  SubscriptionStrings.ratingTitle,
                  style: TextStyle(
                    color: const Color(0xFF949598),
                    fontSize: screenAwareSize(10.0, context),
                    fontFamily: "Montserrat-SemiBold",
                  ),
                ),
                SizedBox(
                  height: screenAwareSize(8.0, context),
                ),
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 8.0,
                    ),
                    const Icon(Icons.star, color: Color(0xFFFFE600)),
                    SizedBox(
                      width: screenAwareSize(5.0, context),
                    ),
                    Text(SubscriptionStrings.ratingValue, style: TextStyle(color: Color(0xFFFFE600))),
                    SizedBox(
                      width: screenAwareSize(5.0, context),
                    ),
                    Text(
                      SubscriptionStrings.bestPrice,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
