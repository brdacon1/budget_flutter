import 'package:firebase_ai/firebase_ai.dart';

/// Único ponto do app que fala com o Gemini (Firebase AI Logic).
///
/// Trabalha só com tipos primitivos/Map: não conhece entities.
/// Stateless — o histórico da conversa mora no repositório.
class ChatAiRemoteDatasource {
  /// Modelo barato e rápido; tarefa é roteamento/conversa curta.
  static const _model = 'gemini-3.5-flash-lite';

  /// Envia [history] (`[{role: 'user'|'model', text}]`) com as [tools]
  /// (`[{name, description, params: {p: {type, values?, description}}}]`) e
  /// devolve `{text, functionCalls: [{name, args}], inputTokens, outputTokens}`.
  Future<Map<String, dynamic>> send({
    required String system,
    required List<Map<String, String>> history,
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
    final response = await model.generateContent([
      for (final m in history)
        m['role'] == 'model'
            ? Content.model([TextPart(m['text']!)])
            : Content.text(m['text']!),
    ]);
    return {
      'text': response.text ?? '',
      'functionCalls': [
        for (final c in response.functionCalls)
          {'name': c.name, 'args': c.args},
      ],
      'inputTokens': response.usageMetadata?.promptTokenCount ?? 0,
      'outputTokens': response.usageMetadata?.candidatesTokenCount ?? 0,
    };
  }

  FunctionDeclaration _toDeclaration(Map<String, dynamic> tool) {
    final params = (tool['params'] as Map).cast<String, Map>();
    return FunctionDeclaration(
      tool['name'] as String,
      tool['description'] as String,
      parameters: {
        for (final e in params.entries)
          e.key:
              e.value['type'] == 'enum'
                  ? Schema.enumString(
                    enumValues: (e.value['values'] as List).cast<String>(),
                    description: e.value['description'] as String?,
                  )
                  : Schema.string(
                    description: e.value['description'] as String?,
                  ),
      },
    );
  }
}
