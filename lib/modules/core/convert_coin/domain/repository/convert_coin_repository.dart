/// Contrato para formatação e conversão de valores monetários.
///
/// Stateless — pode viver como singleton no container de DI.
abstract class ConvertCoinRepository {
  /// Converte um `double` em string formatada de moeda brasileira.
  ///
  /// Exemplo: `10.5` → `'R$ 10,50'`.
  String convertFromDouble(double value);

  /// Converte uma string formatada de moeda brasileira em `double`.
  ///
  /// Exemplo: `'R$ 1.234,56'` → `1234.56`.
  ///
  /// Lança [FormatException] se [value] for nulo ou inválido.
  double convertFromString(String? value);

  /// Converte uma string quantidade (sem os centavos) em `double`.
  ///
  /// Exemplo: `'1.234,56'` → `1234.56`.
  ///
  /// Lança [FormatException] se [value] for nulo ou inválido.
  double convertQtdFromString(String? value);
}
