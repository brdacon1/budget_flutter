import 'dart:ffi';

import 'package:intl/intl.dart';

class convert_coin {
  String convertFromDouble(double value)
  {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String valorConvertido = formatter.format(value);
    return valorConvertido;
  }
  double convertFromString(String? value)
  {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String valorClean = value!.replaceAll(formatter.currencySymbol, '')
        .replaceAll(',', '')
        .replaceAll('.', '');

    double convertValor = double.parse(valorClean) / 100;

    print(convertValor); // Saída: 1000.5

    return convertValor;
  }
}