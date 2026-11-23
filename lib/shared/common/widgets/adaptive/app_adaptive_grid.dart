import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Lista de cards que vira grid em tela larga: o número de colunas sai da
/// largura disponível ([minItemWidth] por coluna, no máximo [maxColumns]).
/// Em largura estreita fica 1 coluna, igual à lista do celular.
///
/// Os cards podem ter alturas diferentes: cada linha do grid tem a altura do
/// seu maior card. Com [mainAxisExtent] os cards têm altura fixa.
class AppAdaptiveGrid extends StatelessWidget {
  const AppAdaptiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minItemWidth = 320,
    this.maxColumns = 3,
    this.mainAxisExtent,
    this.spacing = defaultPadding,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double minItemWidth;
  final int maxColumns;
  final double? mainAxisExtent;
  final double spacing;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - padding.horizontal;
        final columns = ((available + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns);
        if (columns == 1) {
          return ListView.builder(
            controller: controller,
            padding: padding,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
        }
        if (mainAxisExtent != null) {
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
        }
        return ListView.builder(
          controller: controller,
          padding: padding,
          itemCount: (itemCount / columns).ceil(),
          itemBuilder: (context, row) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child:
                        row * columns + c < itemCount
                            ? itemBuilder(context, row * columns + c)
                            : const SizedBox.shrink(),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
