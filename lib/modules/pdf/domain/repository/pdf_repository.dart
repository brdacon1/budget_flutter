import 'package:flutter/foundation.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class PdfRepository extends ChangeNotifier {
  OwnerPdf? get ownerPdf;

  Future<Result<OwnerPdf>> fetchInformationEnterprise({bool forceRefresh = false});
  Future<Result<void>> saveInformationEnterprise(OwnerPdf pdf);
  Future<Result<void>> updateInformationEnterprise(OwnerPdf pdf);

  Future<Result<List<ItemsBudget>>> fetchBudgetItems(String budgetId,
      {bool forceRefresh = false});
  Future<Result<CustomerInfo>> fetchBudgetById(String budgetId,
      {bool forceRefresh = false});
  Future<Result<List<ObservationPdf>>> fetchBudgetComments(String budgetId,
      {bool forceRefresh = false});
}
