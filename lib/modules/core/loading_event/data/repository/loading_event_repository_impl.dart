import 'package:flutter/material.dart';

import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';

class LoadingEventRepositoryImpl implements LoadingEventRepository {
  bool _isLoading = false;

  @override
  Future<void> alertLoading(BuildContext context) async {
    _isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            backgroundColor: bgColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(
                  color: Color(0xFF0DF5E4),
                ),
                SizedBox(height: 16),
                Text(
                  'Aguarde...',
                  style: TextStyle(fontSize: 15, color: Color(0xFF0DF5E4)),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      _isLoading = false;
    });
  }

  @override
  void closeLoading(BuildContext context) {
    if (_isLoading) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
