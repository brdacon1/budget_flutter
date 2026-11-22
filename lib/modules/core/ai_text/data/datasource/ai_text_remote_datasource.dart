import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

/// Geração de texto simples com o Gemini (Firebase AI Logic): sem tools e sem
/// histórico. Junto com `ChatAiRemoteDatasource`, é o único ponto do app que
/// importa `firebase_ai` (ARCHITECTURE §20, P3).
class AiTextRemoteDatasource {
  static const _model = 'gemini-3.5-flash-lite';

  /// Sem resposta nesse tempo → [TimeoutException].
  static const _timeout = Duration(seconds: 15);

  /// [jsonKeys]: quando informado, força a resposta em JSON com essas chaves
  /// (todas string) e `text` vem como o JSON cru.
  ///
  /// Devolve `{text, inputTokens, outputTokens}`.
  Future<Map<String, dynamic>> generate({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: _model,
      systemInstruction: Content.system(system),
      generationConfig: GenerationConfig(
        temperature: 0.3,
        maxOutputTokens: maxOutputTokens,
        responseMimeType: jsonKeys == null ? null : 'application/json',
        responseSchema:
            jsonKeys == null
                ? null
                : Schema.object(
                  properties: {for (final k in jsonKeys) k: Schema.string()},
                ),
      ),
    );
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(_timeout);
    return {
      'text': response.text ?? '',
      'inputTokens': response.usageMetadata?.promptTokenCount ?? 0,
      'outputTokens': response.usageMetadata?.candidatesTokenCount ?? 0,
    };
  }
}
