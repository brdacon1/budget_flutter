/// Recebido × falta receber dos recibos emitidos em um mês.
class MonthReceiptComparison {
  final DateTime month;
  final double received;
  final double toReceive;

  const MonthReceiptComparison({
    required this.month,
    this.received = 0,
    this.toReceive = 0,
  });
}
