import 'package:intl/intl.dart';

class ConvertCoin {
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

    return convertValor;
  }

  double convertQtdFromString(String? value)
  {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String valorClean = value!.replaceAll(formatter.currencySymbol, '')
        .replaceAll(',', '.');

    double convertValor = double.parse(valorClean);

    return convertValor;
  }
}