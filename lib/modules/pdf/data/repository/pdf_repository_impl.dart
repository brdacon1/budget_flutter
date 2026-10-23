import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/pdf/data/datasource/pdf_remote_datasource.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfRepositoryImpl extends PdfRepository {
  final PdfRemoteDataSource _pdfRemote;
  final BudgetRemoteDataSource _budgetRemote;

  PdfRepositoryImpl(this._pdfRemote, this._budgetRemote);

  OwnerPdf? _ownerPdf;
  final Map<String, List<ItemsBudget>> _itemsCache = {};
  final Map<String, CustomerInfo> _budgetCache = {};
  final Map<String, List<ObservationPdf>> _commentCache = {};

  @override
  OwnerPdf? get ownerPdf => _ownerPdf;

  @override
  Future<Result<OwnerPdf>> fetchInformationEnterprise(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _ownerPdf != null) {
      return Result.ok(_ownerPdf!);
    }
    try {
      final raw = await _pdfRemote.getInformationEnterprise();
      _ownerPdf = OwnerPdf.fromJson(raw);
      notifyListeners();
      return Result.ok(_ownerPdf!);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveInformationEnterprise(OwnerPdf pdf) async {
    try {
      await _pdfRemote.saveInformationEnterprise(pdf.toJson());
      _ownerPdf = pdf;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateInformationEnterprise(OwnerPdf pdf) async {
    try {
      await _pdfRemote.updateInformationEnterprise(pdf.toJson());
      _ownerPdf = pdf;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ItemsBudget>>> fetchBudgetItems(String budgetId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _itemsCache.containsKey(budgetId)) {
      return Result.ok(_itemsCache[budgetId]!);
    }
    try {
      final raw = await _budgetRemote.getBudgetItems(budgetId);
      final list = raw.map((e) => ItemsBudget.fromMap(e)).toList();
      _itemsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> fetchBudgetById(String budgetId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _budgetCache.containsKey(budgetId)) {
      return Result.ok(_budgetCache[budgetId]!);
    }
    try {
      final raw = await _budgetRemote.getBudgetById(budgetId);
      final budget = CustomerInfo.fromMap(raw);
      _budgetCache[budgetId] = budget;
      return Result.ok(budget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ObservationPdf>>> fetchBudgetComments(String budgetId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _commentCache.containsKey(budgetId)) {
      return Result.ok(_commentCache[budgetId]!);
    }
    try {
      final raw = await _budgetRemote.getComments(budgetId);
      final list = raw.map((e) => ObservationPdf(
        data: e['DATA'] as String? ?? '',
        observacao: e['OBSERVACAO'] as String? ?? '',
      )).toList();
      _commentCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}

