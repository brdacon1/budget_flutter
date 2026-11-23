import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';

/// Rascunho do orçamento que está sendo criado (ainda não salvo).
///
/// O formulário de criação publica aqui o que o usuário digita e a lista de
/// orçamentos (tela larga) mostra um card "novo" que se atualiza ao vivo.
/// Estado só de tela, em memória: `null` = nenhum orçamento novo em edição.
class BudgetDraftNotifier extends ValueNotifier<CustomerInfo?> {
  BudgetDraftNotifier() : super(null);
}
