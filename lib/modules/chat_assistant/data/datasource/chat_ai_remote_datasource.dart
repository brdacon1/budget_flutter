import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

/// Único ponto do app que fala com o Gemini (Firebase AI Logic).
///
/// Trabalha só com tipos primitivos/Map: não conhece entities.
/// Stateless — o histórico da conversa mora no repositório.
class ChatAiRemoteDatasource {
  /// Modelo barato e rápido; tarefa é roteamento/conversa curta.
  static const _model = 'gemini-3.5-flash-lite';

  /// Sem resposta nesse tempo → [TimeoutException]; o chat cai no modo padrão.
  static const _timeout = Duration(seconds: 20);

  /// [history]: `{role: 'user'|'model', text}`, `{role: 'model', parts: [...]}`
  /// (turno com chamadas de tool, parts cruas) ou
  /// `{role: 'tool', name, response}`.
  ///
  /// [tools]: `{name, description, params: {p: {type, values?, description?,
  /// required?}}}`.
  ///
  /// Devolve `{text, functionCalls: [{name, args}], parts: [...],
  /// inputTokens, outputTokens}`.
  Future<Map<String, dynamic>> send({
    required String system,
    required List<Map<String, Object?>> history,
    List<Map<String, dynamic>> tools = const [],
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: _model,
      systemInstruction: Content.system(system),
      tools:
          tools.isEmpty
              ? null
              : [Tool.functionDeclarations(tools.map(_toDeclaration).toList())],
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 512,
      ),
    );
    final response = await model
        .generateContent(history.map(_toContent))
        .timeout(_timeout);
    final parts =
        response.candidates.isEmpty
            ? const <Part>[]
            : response.candidates.first.content.parts;
    return {
      'text': response.text ?? '',
      'functionCalls': [
        for (final c in response.functionCalls)
          {'name': c.name, 'args': c.args},
      ],
      'parts': [
        for (final p in parts) Map<String, Object?>.from(p.toJson() as Map),
      ],
      'inputTokens': response.usageMetadata?.promptTokenCount ?? 0,
      'outputTokens': response.usageMetadata?.candidatesTokenCount ?? 0,
    };
  }

  Content _toContent(Map<String, Object?> m) {
    switch (m['role']) {
      case 'tool':
        return Content.functionResponse(
          m['name'] as String,
          (m['response'] as Map).cast<String, Object?>(),
        );
      case 'model' when m['parts'] != null:
        // Reenvia as parts exatamente como vieram (preserva thoughtSignature).
        return Content.model([
          for (final p in m['parts'] as List)
            UnknownPart((p as Map).cast<String, Object?>()),
        ]);
      case 'model':
        return Content.model([TextPart(m['text'] as String)]);
      default:
        return Content.text(m['text'] as String);
    }
  }

  FunctionDeclaration _toDeclaration(Map<String, dynamic> tool) {
    final params = (tool['params'] as Map).cast<String, Map>();
    return FunctionDeclaration(
      tool['name'] as String,
      tool['description'] as String,
      parameters: {for (final e in params.entries) e.key: _toSchema(e.value)},
      optionalParameters: [
        for (final e in params.entries)
          if (e.value['required'] != true) e.key,
      ],
    );
  }

  Schema _toSchema(Map p) {
    final description = p['description'] as String?;
    return switch (p['type']) {
      'enum' => Schema.enumString(
        enumValues: (p['values'] as List).cast<String>(),
        description: description,
      ),
      'number' => Schema.number(description: description),
      _ => Schema.string(description: description),
    };
  }
}
