import 'package:oflite/shared/common/constants/colors.dart';
import 'package:material_ui/material_ui.dart';

/// Opções de menu do bot: empilhadas no celular, em 2 colunas quando o balão
/// é largo (tela larga).
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
  static const _gap = 8.0;
  static const _twoColumnsMinWidth = 440.0;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const textStyle = TextStyle(fontWeight: FontWeight.bold);

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
          backgroundColor: _accent,
          foregroundColor: blackColor,
          shape: shape,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Balão largo (tela larga): opções em 2 colunas; "voltar" (valor '0')
        // fica sozinho na última linha. Estreito (celular): empilhadas.
        final twoColumns = constraints.maxWidth >= _twoColumnsMinWidth;
        final regular = [
          for (final o in options)
            if (o['value'] != '0') o,
        ];
        final back = [
          for (final o in options)
            if (o['value'] == '0') o,
        ];
        if (!twoColumns) {
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
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pares com a mesma altura (um rótulo longo quebra em 2 linhas).
              for (var i = 0; i < regular.length; i += 2) ...[
                if (i > 0) const SizedBox(height: _gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: button(regular[i])),
                      const SizedBox(width: _gap),
                      Expanded(
                        child:
                            i + 1 < regular.length
                                ? button(regular[i + 1])
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
              for (final option in back) ...[
                const SizedBox(height: _gap),
                button(option),
              ],
            ],
          ),
        );
      },
    );
  }

  VoidCallback? _onPressed(Map<String, String> option) {
    if (!enabled) return null;
    return () => onSelect?.call(option['value'] ?? '', option['label'] ?? '');
  }
}
