import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/constants.dart';
import '../payment_creator_view_model.dart';

class PaymentSaveButton extends StatelessWidget {
  final PaymentCreatorViewModel viewModel;
  final VoidCallback onPressed;

  const PaymentSaveButton({
    super.key,
    required this.viewModel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          padding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          viewModel.nameButton!,
          style: GoogleFonts.heebo(
            color: Colors.black,
            letterSpacing: 0.5,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
