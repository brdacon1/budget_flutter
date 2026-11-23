import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_master_detail.dart';

class _Detail extends StatelessWidget {
  const _Detail(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(label),
      ),
    ),
  );
}

void main() {
  testWidgets('abre, troca e fecha o detalhe sem sair da lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey<NavigatorState>();
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppMasterDetail(
          master: const Center(child: Text('lista')),
          emptyDetail: const Center(child: Text('vazio')),
          detailNavigatorKey: key,
          onDetailClosed: () => closed++,
        ),
      ),
    );
    expect(find.text('vazio'), findsOneWidget);
    expect(tester.getSize(find.text('lista')).width, lessThan(380));

    void open(String label) => key.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => _Detail(label)),
      (r) => r.isFirst,
    );

    open('A');
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('lista'), findsOneWidget);

    // Trocar de item não conta como fechar.
    open('B');
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    expect(closed, 0);

    // Voltar fecha o detalhe e mostra o estado vazio; lista segue visível.
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('vazio'), findsOneWidget);
    expect(find.text('lista'), findsOneWidget);
    expect(closed, 1);
  });

  for (final hide in [true, false]) {
    testWidgets('hideBackOnRootScreens=$hide chega às telas do painel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1194, 834);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final key = GlobalKey<NavigatorState>();
      bool? seen;
      await tester.pumpWidget(
        MaterialApp(
          home: AppMasterDetail(
            master: const SizedBox(),
            emptyDetail: const SizedBox(),
            detailNavigatorKey: key,
            hideBackOnRootScreens: hide,
          ),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) {
            seen = AppDetailPane.hidesBackOf(context);
            return const SizedBox();
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(seen, hide);
    });
  }

  testWidgets('fora de um painel, hidesBackOf é falso', (tester) async {
    bool? seen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            seen = AppDetailPane.hidesBackOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, isFalse);
  });
}
