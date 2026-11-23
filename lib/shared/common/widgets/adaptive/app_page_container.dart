import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';

/// Largura máxima do conteúdo (DESIGN_SYSTEM §4 / ARCHITECTURE §22).
enum AppPageWidth {
  /// Login / cadastro.
  auth(480),

  /// Formulários.
  form(720),

  /// Texto corrido e chat.
  reading(820),

  /// Listas e grids.
  wide(1200);

  const AppPageWidth(this.maxWidth);
  final double maxWidth;
}

/// Centraliza o conteúdo com largura máxima em telas largas. Em `compact`
/// não limita nada (comportamento atual do celular).
class AppPageContainer extends StatelessWidget {
  const AppPageContainer({
    super.key,
    required this.child,
    this.width = AppPageWidth.form,
  });

  final Widget child;
  final AppPageWidth width;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isMobile(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.maxWidth),
        child: child,
      ),
    );
  }
}
