import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import '../../../common/constants/constants.dart';
import '../../../common/constants/subscription_constants.dart';
import '../../../common/utils/height_calculate_utils.dart';

class ProductScreenBottomPart extends StatefulWidget {
  final VoidCallback onSubscribe;
  final bool isLoading;

  const ProductScreenBottomPart({
    Key? key,
    required this.onSubscribe,
    required this.isLoading,
  }) : super(key: key);

  @override
  _ProductScreenBottomPartState createState() =>
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
        colorItem(colors[i], i == currentColorIndex, context, () {
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
          Padding(
            padding: EdgeInsets.only(left: screenAwareSize(20.0, context)),
            child: Text(
              "Benefícios",
              style: TextStyle(
                color: const Color(0xFF949598),
                fontSize: screenAwareSize(12.0, context),
                fontFamily: "Montserrat-SemiBold",
              ),
            ),
          ),
          SizedBox(
            height: screenAwareSize(8.0, context),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: screenAwareSize(26.0, context),
                right: screenAwareSize(18.0, context)),
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
          ),
          Padding(
            padding: EdgeInsets.only(
                left: screenAwareSize(26.0, context),
                right: screenAwareSize(18.0, context)),
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
          ),
          SizedBox(
            height: screenAwareSize(14.0, context),
          ),
          const SizedBox(
            height: 8.0,
          ),
          SizedBox(
            height: screenAwareSize(8.0, context),
          ),
          Padding(
            padding: EdgeInsets.only(left: screenAwareSize(20.0, context)),
            child: const Text(
              "Preço",
              style: TextStyle(
                color: Color(0xFF949598),
                fontFamily: "Montserrat-SemiBold",
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: screenAwareSize(120.0, context),
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: screenAwareSize(22.0, context)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                            left: screenAwareSize(18.0, context)),
                        child: Row(
                          children: <Widget>[
                            Text(
                              "R\$ ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenAwareSize(26.0, context),
                                fontFamily: "Montserrat-Medium",
                              ),
                            ),
                            SizedBox(width: screenAwareSize(2.0, context)),
                            Text(
                              "3,59/mês",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenAwareSize(20.0, context),
                                fontFamily: "Montserrat-Medium",
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: screenAwareSize(15.0, context),
                      ),
                      FadeAnimationWidget(
                        delay: 1,
                        child: TextButton(
                          onPressed: widget.isLoading ? null : widget.onSubscribe,
                          style: TextButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 125),
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
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget colorItem(
    Color color, bool isSelected, BuildContext context, VoidCallback _ontab) {
  return GestureDetector(
    onTap: _ontab,
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
                    color: Colors.black.withOpacity(.8),
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  )
                ]
              : []),
        child: ClipPath(
          clipper: MClipper(),
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

class MClipper extends CustomClipper<Path> {
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
