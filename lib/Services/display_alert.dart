import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

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
