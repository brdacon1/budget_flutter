import 'package:material_ui/material_ui.dart';

/// Classe de tamanho da janela (ARCHITECTURE §22).
///
/// - [compact]: < 600 (celular)
/// - [medium]: 600–1023 (tablet pequeno / janela estreita)
/// - [expanded]: >= 1024 (iPad deitado, web)
enum WindowSize { compact, medium, expanded }

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  static WindowSize sizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedBreakpoint) return WindowSize.expanded;
    if (width >= mediumBreakpoint) return WindowSize.medium;
    return WindowSize.compact;
  }

  static bool isMobile(BuildContext context) =>
      sizeOf(context) == WindowSize.compact;

  static bool isTablet(BuildContext context) =>
      sizeOf(context) == WindowSize.medium;

  static bool isDesktop(BuildContext context) =>
      sizeOf(context) == WindowSize.expanded;

  @override
  Widget build(BuildContext context) {
    switch (sizeOf(context)) {
      case WindowSize.expanded:
        return desktop;
      case WindowSize.medium:
        return tablet ?? mobile;
      case WindowSize.compact:
        return mobile;
    }
  }
}
