import 'package:intl/intl.dart';

import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';

/// Implementação pura de formatação monetária (sem I/O).
class ConvertCoinRepositoryImpl implements ConvertCoinRepository {
  @override
  String convertFromDouble(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }

  @override
  double convertFromString(String? value) {
    // Mantém só dígitos: cobre campo vazio, símbolo, espaços (inclusive NBSP).
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return (double.tryParse(digits) ?? 0) / 100;
  }

  @override
  double convertQtdFromString(String? value) {
    final clean = (value ?? '')
        .replaceAll(RegExp(r'[^0-9,.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(clean) ?? 0;
  }
}
