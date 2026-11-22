import 'package:oflite/shared/design_pattern/result.dart';

/// Contrato de geração de texto simples com IA.
abstract class AiTextRepository {
  /// Texto gerado (ou o JSON cru quando [jsonKeys] é informado).
  Future<Result<String>> generate({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
  });

  /// Chamadas já usadas em [day] (`yyyy-MM-dd`).
  Future<int> usageOf(String day);

  Future<void> saveUsage(String day, int count);
}
