import 'package:oflite/modules/budget/data/datasource/budget_remote_datasource.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/data/datasource/pdf_remote_datasource.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class PdfRepositoryImpl extends PdfRepository {
  final PdfRemoteDataSource _pdfRemote;
  final BudgetRemoteDataSource _budgetRemote;
  final UserRepository _userRepository;

  PdfRepositoryImpl(this._pdfRemote, this._budgetRemote, this._userRepository);

  String? get _userUid => _userRepository.selectUser.value?.user;

  OwnerPdf? _ownerPdf;
  final Map<String, List<ItemsBudget>> _itemsCache = {};
  final Map<String, CustomerInfo> _budgetCache = {};
  final Map<String, List<ObservationPdf>> _commentCache = {};

  @override
  OwnerPdf? get ownerPdf => _ownerPdf;

  @override
  Future<Result<OwnerPdf>> fetchInformationEnterprise({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _ownerPdf != null) {
      return Result.ok(_ownerPdf!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _pdfRemote.getInformationEnterprise(userUid);
      _ownerPdf = OwnerPdf.fromJson(raw);
      notifyListeners();
      return Result.ok(_ownerPdf!);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveInformationEnterprise(OwnerPdf pdf) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _pdfRemote.saveInformationEnterprise(userUid, pdf.toJson());
      _ownerPdf = pdf;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateInformationEnterprise(OwnerPdf pdf) async {
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      await _pdfRemote.updateInformationEnterprise(userUid, pdf.toJson());
      _ownerPdf = pdf;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ItemsBudget>>> fetchBudgetItems(
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _itemsCache.containsKey(budgetId)) {
      return Result.ok(_itemsCache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _budgetRemote.getBudgetItems(userUid, budgetId);
      final list = raw.map((e) => ItemsBudget.fromMap(e)).toList();
      _itemsCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<CustomerInfo>> fetchBudgetById(
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _budgetCache.containsKey(budgetId)) {
      return Result.ok(_budgetCache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _budgetRemote.getBudgetById(userUid, budgetId);
      final budget = CustomerInfo.fromMap(raw);
      _budgetCache[budgetId] = budget;
      return Result.ok(budget);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<ObservationPdf>>> fetchBudgetComments(
    String budgetId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _commentCache.containsKey(budgetId)) {
      return Result.ok(_commentCache[budgetId]!);
    }
    final userUid = _userUid;
    if (userUid == null || userUid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      final raw = await _budgetRemote.getComments(userUid, budgetId);
      final list = raw.map((e) => ObservationPdf.fromMap(e)).toList();
      _commentCache[budgetId] = list;
      return Result.ok(list);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
