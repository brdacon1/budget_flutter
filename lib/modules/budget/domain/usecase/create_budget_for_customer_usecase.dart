import 'package:intl/intl.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Cria um orçamento novo (sem itens) com os dados do cliente de [source].
///
/// Salva antes de abrir a tela: a aba "Itens" só abre com orçamento salvo.
class CreateBudgetForCustomerUsecase {
  final BudgetRepository _repo;

  const CreateBudgetForCustomerUsecase(this._repo);

  Future<Result<CustomerInfo>> call(CustomerInfo source) async {
    final budget = CustomerInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      status: 'PENDENTE',
      totalValue: 0,
      generated: '',
      customerName: source.customerName,
      phone: source.phone,
      email: source.email,
      address: source.address,
      zip: source.zip,
      street: source.street,
      city: source.city,
      neighborhood: source.neighborhood,
    );
    final result = await _repo.saveBudget(budget);
    return switch (result) {
      Ok() => Result.ok(budget),
      Error(:final error) => Result.error(error),
    };
  }
}
