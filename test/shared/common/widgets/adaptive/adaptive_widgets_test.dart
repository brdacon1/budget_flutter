import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('ResponsiveWidget.sizeOf', () {
    for (final c in {
      const Size(390, 844): WindowSize.compact,
      const Size(599, 800): WindowSize.compact,
      const Size(600, 800): WindowSize.medium,
      const Size(1023, 768): WindowSize.medium,
      const Size(1024, 768): WindowSize.expanded,
      const Size(1366, 1024): WindowSize.expanded,
    }.entries) {
      testWidgets('${c.key.width.toInt()} -> ${c.value}', (tester) async {
        late WindowSize result;
        await _pump(
          tester,
          c.key,
          Builder(
            builder: (context) {
              result = ResponsiveWidget.sizeOf(context);
              return const SizedBox();
            },
          ),
        );
        expect(result, c.value);
      });
    }
  });

  group('AppPageContainer', () {
    const key = Key('content');
    testWidgets('compact não limita a largura', (tester) async {
      await _pump(
        tester,
        const Size(390, 844),
        const AppPageContainer(child: SizedBox.expand(key: key)),
      );
      expect(tester.getSize(find.byKey(key)).width, 390);
    });

    testWidgets('expanded limita e centraliza', (tester) async {
      await _pump(
        tester,
        const Size(1194, 834),
        const AppPageContainer(child: SizedBox.expand(key: key)),
      );
      expect(tester.getSize(find.byKey(key)).width, AppPageWidth.form.maxWidth);
      expect(tester.getCenter(find.byKey(key)).dx, 1194 / 2);
    });
  });

  group('AppAdaptiveGrid', () {
    Widget grid() => AppAdaptiveGrid(
      itemCount: 6,
      mainAxisExtent: 80,
      itemBuilder: (_, i) => SizedBox(key: ValueKey(i), height: 80),
    );

    testWidgets('estreito = 1 coluna', (tester) async {
      await _pump(tester, const Size(390, 844), grid());
      expect(tester.getTopLeft(find.byKey(const ValueKey(1))).dx, 0);
      expect(tester.getTopLeft(find.byKey(const ValueKey(1))).dy, greaterThan(0));
    });

    testWidgets('largo = várias colunas', (tester) async {
      await _pump(tester, const Size(1194, 834), grid());
      expect(
        tester.getTopLeft(find.byKey(const ValueKey(1))).dy,
        tester.getTopLeft(find.byKey(const ValueKey(0))).dy,
      );
    });

    testWidgets('altura variável: linhas lado a lado e no máximo 3 colunas', (
      tester,
    ) async {
      await _pump(
        tester,
        const Size(1600, 900),
        AppAdaptiveGrid(
          itemCount: 7,
          itemBuilder:
              (_, i) => SizedBox(key: ValueKey(i), height: i.isEven ? 60 : 100),
        ),
      );
      Offset at(int i) => tester.getTopLeft(find.byKey(ValueKey(i)));
      // 3 colunas (teto), mesmo topo na linha.
      expect(at(1).dy, at(0).dy);
      expect(at(2).dy, at(0).dy);
      expect(at(3).dx, at(0).dx);
      // A linha seguinte começa abaixo do maior card da anterior (100).
      expect(at(3).dy, greaterThanOrEqualTo(at(0).dy + 100));
      expect(at(1).dx, greaterThan(at(0).dx));
    });
  });
}
