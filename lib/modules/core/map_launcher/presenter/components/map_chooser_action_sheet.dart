import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:map_launcher/map_launcher.dart';

/// iOS: action sheet nativa para escolher o app de mapa.
/// Com um único app, abre direto sem mostrar a sheet.
Future<void> showMapChooserSheet(
  BuildContext context, {
  required List<SupportedMap> maps,
  required String title,
  required String cancelLabel,
}) async {
  if (maps.isEmpty) return;
  if (maps.length == 1) return maps.first.show();
  await showCupertinoModalPopup<void>(
    context: context,
    builder:
        (sheetContext) => CupertinoActionSheet(
          title: Text(title),
          actions: [
            for (final map in maps)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  map.show();
                },
                child: Text(map.name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: Text(cancelLabel),
          ),
        ),
  );
}
