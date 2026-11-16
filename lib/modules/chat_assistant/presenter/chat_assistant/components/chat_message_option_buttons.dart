import 'package:material_ui/material_ui.dart';

/// Opções de menu do bot em botões empilhados (um embaixo do outro).
///
/// Cada opção é `{'label': ..., 'value': ...}`. A opção com `value` `'0'`
/// (voltar ao menu) é exibida por último em estilo contornado.
class ChatMessageOptionButtons extends StatelessWidget {
  const ChatMessageOptionButtons({
    super.key,
    required this.options,
    required this.enabled,
    required this.onSelect,
  });

  final List<Map<String, String>> options;
  final bool enabled;
  final void Function(String value, String label)? onSelect;

  static const _accent = Color(0xFF00BFA5);

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const textStyle = TextStyle(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          const SizedBox(height: 8),
          if (option['value'] == '0')
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: BorderSide(
                  color: enabled ? Colors.cyanAccent : Colors.white24,
                ),
                shape: shape,
                padding: padding,
              ),
              onPressed: _onPressed(option),
              child: Text(option['label'] ?? '', style: textStyle),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.black,
                shape: shape,
                padding: padding,
              ),
              onPressed: _onPressed(option),
              child: Text(
                option['label'] ?? '',
                style: textStyle,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }

  VoidCallback? _onPressed(Map<String, String> option) {
    if (!enabled) return null;
    return () => onSelect?.call(option['value'] ?? '', option['label'] ?? '');
  }
}
