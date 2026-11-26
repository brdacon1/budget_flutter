import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/presenter/budget_options/budget_options_view.dart';

/// Painel da direita do iPad: a aba "Mais" do orçamento aberto. Tem
/// `Navigator` próprio, então as opções (métricas, recibos, PDF…) abrem
/// dentro do painel e a lista e o formulário continuam visíveis.
class BudgetOptionsPane extends StatelessWidget {
  const BudgetOptionsPane({super.key, required this.item});

  final CustomerInfo item;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute:
          (_) => MaterialPageRoute<void>(
            builder: (_) => BudgetOptionsView(item: item),
          ),
    );
  }
}
