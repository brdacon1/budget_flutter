import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/main_tab/presenter/components/main_tab_company_logo.dart';

// PNG 1x1 transparente.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));

void main() {
  testWidgets('círculo do tamanho padrão com a foto da empresa', (
    tester,
  ) async {
    await _pump(tester, MainTabCompanyLogo(logo: _png));
    expect(
      tester.getSize(find.byType(MainTabCompanyLogo)),
      const Size(MainTabCompanyLogo.size, MainTabCompanyLogo.size),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.business), findsNothing);
  });

  testWidgets('sem logo mostra o ícone neutro', (tester) async {
    await _pump(tester, const MainTabCompanyLogo());
    expect(
      tester.getSize(find.byType(MainTabCompanyLogo)),
      const Size(MainTabCompanyLogo.size, MainTabCompanyLogo.size),
    );
    expect(find.byIcon(Icons.business), findsOneWidget);
  });
}
