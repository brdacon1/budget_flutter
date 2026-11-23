import 'package:oflite/shared/common/constants/colors.dart';
import 'package:material_ui/material_ui.dart';

/// Opções de menu do bot em botões empilhados (um embaixo do outro), em
/// qualquer largura de tela.
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

  static const _accent = chatSendButtonColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    const textStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5);

    Widget button(Map<String, String> option) {
      if (option['value'] == '0') {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: chatHighlightColor,
            side: BorderSide(
              color: enabled ? chatHighlightColor : chatOptionBorderColor,
            ),
            shape: shape,
            padding: padding,
          ),
          onPressed: _onPressed(option),
          child: Text(option['label'] ?? '', style: textStyle),
        );
      }
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _accent.withValues(alpha: 0.14),
          disabledBackgroundColor: whiteColor.withValues(alpha: 0.04),
          foregroundColor: whiteColor,
          disabledForegroundColor: whiteColor.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color:
                  enabled
                      ? _accent.withValues(alpha: 0.55)
                      : chatOptionBorderColor,
            ),
          ),
          padding: padding,
        ),
        onPressed: _onPressed(option),
        child: Text(
          option['label'] ?? '',
          style: textStyle,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options) ...[
          const SizedBox(height: 8),
          button(option),
        ],
      ],
    );
  }

  VoidCallback? _onPressed(Map<String, String> option) {
    if (!enabled) return null;
    return () => onSelect?.call(option['value'] ?? '', option['label'] ?? '');
  }
}
