import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';

class LoadingEventRepositoryImpl implements LoadingEventRepository {
  bool _isLoading = false;

  @override
  Future<void> alertLoading(BuildContext context) async {
    // Já existe um loading aberto: abrir outro deixaria um diálogo órfão
    // que o closeLoading nunca fecha (tela presa em "Aguarde...").
    if (_isLoading) return;
    _isLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const PopScope(
          canPop: false, // Prevents closing the dialog via the back button
          child: AlertDialog(
            backgroundColor: bgColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: Color(0xFF0DF5E4)),
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
      _isLoading = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
