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
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String valorClean = value!
        .replaceAll(formatter.currencySymbol, '')
        .replaceAll(',', '')
        .replaceAll('.', '');

    return double.parse(valorClean) / 100;
  }

  @override
  double convertQtdFromString(String? value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String valorClean = value!
        .replaceAll(formatter.currencySymbol, '')
        .replaceAll(',', '.');

    return double.parse(valorClean);
  }
}
