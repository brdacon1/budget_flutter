import 'package:oflite/modules/budget/data/model/customer_info_model.dart';

/// Uma página de orçamentos. [cursor] é o ID do último orçamento lido (de
/// onde a próxima página continua); [hasMore] diz se ainda há o que ler.
class BudgetPage {
  final List<CustomerInfo> items;
  final String? cursor;
  final bool hasMore;

  const BudgetPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });
}
