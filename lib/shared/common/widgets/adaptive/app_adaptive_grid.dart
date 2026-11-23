import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Lista de cards que vira grid em tela larga: o número de colunas sai da
/// largura disponível ([minItemWidth] por coluna). Em largura estreita fica
/// 1 coluna, igual à lista do celular.
class AppAdaptiveGrid extends StatelessWidget {
  const AppAdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 360,
    this.mainAxisExtent,
    this.spacing = defaultPadding,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;

  /// Altura fixa de cada card; `null` = altura do conteúdo não é suportada
  /// pelo grid, então informe quando os cards tiverem altura previsível.
  final double? mainAxisExtent;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor();
        if (columns <= 1 || mainAxisExtent == null) {
          return ListView.builder(
            controller: controller,
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        return GridView.builder(
          controller: controller,
          padding: padding,
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
