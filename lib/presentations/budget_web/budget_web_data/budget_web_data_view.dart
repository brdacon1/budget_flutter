import 'package:flutter/material.dart';
import 'package:oflite/common/strings/budget_web_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'components/budget_web_data_section.dart';

/// Tab "Meus dados" (read-only) do orçamento Web.
///
/// Exibe os dados do cliente/orçamento sem edição nenhuma, reutilizando as
/// mesmas labels do app mobile. Component `Stateless` — recebe o
/// `CustomerInfo` já carregado pelo `BudgetWebBudgetViewModel`.
class BudgetWebDataView extends StatelessWidget {
  const BudgetWebDataView({super.key, required this.budget});

  final CustomerInfo budget;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      children: [
        BudgetWebDataSection(
          title: BudgetWebStrings.sectionContact,
          icon: Icons.person_outlined,
          rows: [
            BudgetWebDataRow(
                BudgetWebStrings.labelCustomerName,
                _orEmpty(budget.customerName)),
            BudgetWebDataRow(
                BudgetWebStrings.labelPhone, _orEmpty(budget.phone)),
          ],
        ),
        BudgetWebDataSection(
          title: BudgetWebStrings.sectionInfo,
          icon: Icons.request_page_outlined,
          rows: [
            BudgetWebDataRow(
                BudgetWebStrings.labelStatus, _orEmpty(budget.status)),
            BudgetWebDataRow(
                BudgetWebStrings.labelDate, _orEmpty(budget.data)),
            BudgetWebDataRow(
                BudgetWebStrings.labelNumber, _orEmpty(budget.id)),
          ],
        ),
        BudgetWebDataSection(
          title: BudgetWebStrings.sectionAddress,
          icon: Icons.location_on_outlined,
          rows: [
            BudgetWebDataRow(BudgetWebStrings.labelCep, _orEmpty(budget.zip)),
            BudgetWebDataRow(
                BudgetWebStrings.labelStreet, _orEmpty(budget.street)),
            BudgetWebDataRow(
                BudgetWebStrings.labelCity, _orEmpty(budget.city)),
            BudgetWebDataRow(BudgetWebStrings.labelNeighborhood,
                _orEmpty(budget.neighborhood)),
          ],
        ),
      ],
    );
  }

  String _orEmpty(String? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty || s == 'null') return '-';
    return s;
  }
}
