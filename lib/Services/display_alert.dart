import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../anmition/fadeanimation.dart';
import '../constants.dart';

TextEditingController _emailText = TextEditingController();
TextEditingController _passwordText = TextEditingController();
final FirebaseAuth _auth = FirebaseAuth.instance;

class DisplayAlert {
  Future<void> notificationError(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        animType: AnimType.leftSlide,
        headerAnimationLoop: false,
        dialogType: DialogType.error,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
        btnOkOnPress: () => completer.complete(),
        btnOkIcon: Icons.check_circle,
      ).show();
    });

    return completer.future;
  }

  Future<void> dialogChangePassword(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    _emailText.text = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(5),
          backgroundColor: bgColor,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 260,
                width: we,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              Navigator.pop(context, true);
                            });
                          },
                          child: Container(
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.only(right: we * 0.1),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: we * 0.13),
                          child: Text(
                            "Recuperação de senha",
                            style: GoogleFonts.heebo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: he * 0.02,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: Card(
                          color: Colors.cyan[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(padding: const EdgeInsets.only(left: 5, right: 5),
                                      child:Container(
                                        width: we * 0.8,
                                        height: he * 0.071,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: bgColor,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child:  TextField(
                                          controller: _emailText,
                                          decoration: const InputDecoration(
                                            enabledBorder: InputBorder.none,
                                            border:InputBorder.none,
                                            prefixIcon: Icon(Icons.email_outlined, color: Colors.white),
                                            hintText: 'E-mail',
                                            hintStyle: TextStyle(
                                              color: bgColor,
                                            ),
                                          ),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 15),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TextButton(
                          onPressed: () async {
                            await _auth.sendPasswordResetEmail(
                              email: _emailText.text.trim(),
                            ).then((value) async => {
                              notification(context, "Feito!", "Você recebeu um email para trocar de senha")
                            });

                          },
                          style: TextButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 70,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: Text(
                            "Solicitar senha",
                            style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((value) async {

    });
  }

  Future<void> notification(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        headerAnimationLoop: false,
        dialogType: DialogType.success,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
        btnOkIcon: Icons.check_circle,
        btnOkOnPress: () {
          Navigator.pop(context, true);
          completer.complete();
        },
      ).show();
    });

    return completer.future;
  }
}
