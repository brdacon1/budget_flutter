import 'package:material_ui/material_ui.dart';

/// Largura máxima do bottom sheet. Em tela larga o sheet fica centralizado
/// em vez de esticar de borda a borda (ARCHITECTURE §22).
const double appModalMaxWidth = 640;

/// Ponto único de abertura de bottom sheets do app. O visual continua sendo
/// do [AppBottomModal]; aqui só limitamos a largura.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: appModalMaxWidth),
    builder: builder,
  );
}
