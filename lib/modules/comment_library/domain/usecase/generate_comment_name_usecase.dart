import 'dart:convert';

import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Gera o nome do comentário (assunto em 2 a 5 palavras) com IA.
///
/// Nunca falha: sem IA (erro, timeout, limite, resposta ruim) devolve
/// [fallbackName] — o cadastro não pode travar por causa da IA.
class GenerateCommentNameUsecase {
  static const maxLength = 40;

  static const system =
      'Você nomeia comentários de orçamentos de prestadores de serviço. '
      'Leia o texto e responda só JSON {"name": "..."} com 2 a 5 palavras '
      'que resumam o assunto (ex.: Garantia de 90 dias, Forma de pagamento). '
      'Use o mesmo idioma do texto. Sem pontuação final.';

  final GenerateAiTextUsecase _ai;

  GenerateCommentNameUsecase(this._ai);

  Future<String> call(String text) async {
    final result = await _ai(
      system: system,
      prompt: text,
      maxOutputTokens: 64,
      jsonKeys: const ['name'],
    );
    if (result is Ok<String>) {
      final name = _clean(_parse(result.value));
      if (name.isNotEmpty) return name;
    }
    return fallbackName(text);
  }

  /// Primeiras palavras do texto, até [maxLength] caracteres.
  String fallbackName(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    var name = '';
    for (final w in words) {
      final next = name.isEmpty ? w : '$name $w';
      if (next.length > maxLength) break;
      name = next;
    }
    if (name.isEmpty) name = text.trim().substring(0, maxLength);
    return _clean(name);
  }

  String _parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['name'] is String) {
        return decoded['name'] as String;
      }
    } on FormatException {
      // Modelo ignorou o JSON: aproveita o texto cru.
    }
    return raw;
  }

  String _clean(String name) {
    var s = name
        .replaceAll(RegExp('["“”\']'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    s = s.replaceAll(RegExp(r'[.,;:!?]+$'), '').trim();
    if (s.length > maxLength) s = s.substring(0, maxLength).trim();
    return s;
  }
}
