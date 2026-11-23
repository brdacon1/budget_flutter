import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/main_tab/presenter/components/main_tab_side_bar.dart';
import 'package:oflite/modules/main_tab/presenter/main_tab_view_model.dart';

void main() {
  final items = [
    TabItem(icon: Icons.support_agent, title: 'Assistente'),
    TabItem(icon: Icons.inventory_outlined, title: 'Orçamentos'),
    TabItem(icon: Icons.dashboard, title: 'Dashboard'),
  ];

  testWidgets('mostra os itens e avisa o toque', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MainTabSideBar(
                items: items,
                currentIndex: 1,
                onTap: (i) => tapped = i,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    for (final item in items) {
      expect(find.text(item.title), findsOneWidget);
    }
    expect(tester.getSize(find.byType(MainTabSideBar)).width, 168);

    await tester.tap(find.text('Dashboard'));
    expect(tapped, 2);
  });
}
