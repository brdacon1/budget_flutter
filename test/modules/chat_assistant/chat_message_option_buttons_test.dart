import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/components/chat_message_option_buttons.dart';

void main() {
  testWidgets('opções ficam uma embaixo da outra, mesmo em balão largo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: ChatMessageOptionButtons(
              options: const [
                {'label': 'Criar orçamentos', 'value': '1'},
                {'label': 'Editar PDF', 'value': '2'},
                {'label': 'Relatórios', 'value': '3'},
              ],
              enabled: true,
              onSelect: (_, __) {},
            ),
          ),
        ),
      ),
    );
    final first = tester.getRect(find.text('Criar orçamentos'));
    final second = tester.getRect(find.text('Editar PDF'));
    final third = tester.getRect(find.text('Relatórios'));
    expect(second.top, greaterThan(first.bottom));
    expect(third.top, greaterThan(second.bottom));
    // Botões ocupam a largura toda (não ficam lado a lado).
    final buttons = find.byType(ElevatedButton);
    expect(buttons, findsNWidgets(3));
    expect(tester.getSize(buttons.first).width, 800);
  });
}
