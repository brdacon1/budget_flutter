import 'package:flutter/foundation.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/customer_info.dart';
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
