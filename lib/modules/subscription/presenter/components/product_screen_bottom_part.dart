import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/constants/subscription_constants.dart';
import 'package:oflite/shared/common/utils/height_calculate_utils.dart';

class ProductScreenBottomPart extends StatefulWidget {
  final String? price;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final bool isLoading;

  const ProductScreenBottomPart({
    super.key,
    this.price,
    required this.onSubscribe,
    required this.onRestore,
    required this.isLoading,
  });

  @override
  State<ProductScreenBottomPart> createState() =>
      _ProductScreenBottomPartState();
}

class _ProductScreenBottomPartState extends State<ProductScreenBottomPart> {
  bool isExpanded = false;
  int currentColorIndex = 0;
  List<Widget> colorItemList = [];

  void _expand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  List<Widget> colorSelector() {
    colorItemList.clear();
    for (var i = 0; i < colors.length; i++) {
      colorItemList.add(
        _colorItem(colors[i], i == currentColorIndex, () {
          setState(() {
            currentColorIndex = i;
          });
        }),
      );
    }
    return colorItemList;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildBenefits(),
          SizedBox(height: screenAwareSize(14.0, context)),
          const SizedBox(height: 8.0),
          SizedBox(height: screenAwareSize(8.0, context)),
          _buildPrice(),
        ],
      ),
    );
  }

  // ---------------- Benefícios ----------------

  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenAwareSize(20.0, context),
          ),
          child: Text(
            "Benefícios",
            style: TextStyle(
              color: const Color(0xFF949598),
              fontSize: screenAwareSize(12.0, context),
              fontFamily: "Montserrat-SemiBold",
            ),
          ),
        ),
        SizedBox(height: screenAwareSize(8.0, context)),
        _buildDescription(),
        _buildExpandToggle(),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenAwareSize(20.0, context),
      ),
      child: AnimatedCrossFade(
        firstChild: Text(
          desc,
          maxLines: 2,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenAwareSize(14.0, context),
            fontFamily: "Montserrat-Medium",
          ),
        ),
        secondChild: Text(
          desc,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenAwareSize(14.0, context),
            fontFamily: "Montserrat-Medium",
          ),
        ),
        crossFadeState: isExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: kThemeAnimationDuration,
      ),
    );
  }

  Widget _buildExpandToggle() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenAwareSize(20.0, context),
      ),
      child: GestureDetector(
        onTap: _expand,
        child: Text(
          isExpanded ? "menos" : "mais..",
          style: const TextStyle(
            color: Color(0xFFFB382F),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ---------------- Preço ----------------

  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenAwareSize(20.0, context),
          ),
          child: const Text(
            "Preço",
            style: TextStyle(
              color: Color(0xFF949598),
              fontFamily: "Montserrat-SemiBold",
            ),
          ),
        ),
        SizedBox(height: screenAwareSize(15.0, context)),
        _buildPriceValue(),
        SizedBox(height: screenAwareSize(15.0, context)),
        _buildSubscribeButton(),
        SizedBox(height: screenAwareSize(10.0, context)),
        _buildRestoreButton(),
      ],
    );
  }

  Widget _buildPriceValue() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenAwareSize(20.0, context),
      ),
      child: Text(
        widget.price ?? "R\$ 3,59/mês",
        style: TextStyle(
          color: Colors.white,
          fontSize: screenAwareSize(22.0, context),
          fontFamily: "Montserrat-Medium",
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenAwareSize(20.0, context),
      ),
      child: FadeAnimationWidget(
        delay: 1,
        child: SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onSubscribe,
            style: TextButton.styleFrom(
              backgroundColor: buttonColor,
              minimumSize: const Size.fromHeight(50),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    "ASSINAR",
                    style: GoogleFonts.heebo(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Center(
      child: TextButton(
        onPressed: widget.isLoading ? null : widget.onRestore,
        child: Text(
          "Restaurar Compras",
          style: TextStyle(
            color: buttonColor,
            fontSize: screenAwareSize(12.0, context),
            fontFamily: "Montserrat-Medium",
          ),
        ),
      ),
    );
  }


  // ---------------- Color selector (interno) ----------------

  Widget _colorItem(Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: screenAwareSize(10.0, context)),
        child: Container(
          width: screenAwareSize(30.0, context),
          height: screenAwareSize(30.0, context),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(5.0),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .8),
                      blurRadius: 10.0,
                      offset: const Offset(0.0, 10.0),
                    )
                  ]
                : [],
          ),
          child: ClipPath(
            clipper: _MClipper(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _MClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0.0, size.height);
    path.lineTo(size.width * 0.2, size.height);
    path.lineTo(size.width, size.height * 0.2);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
