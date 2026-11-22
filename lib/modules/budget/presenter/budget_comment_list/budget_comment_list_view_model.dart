import 'package:flutter/foundation.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado da lista de comentários do orçamento: carga, seleção pelo check
/// circular e remoção em massa (mesmo fluxo da lista de preço/orçamentos).
class BudgetCommentListViewModel extends ChangeNotifier {
  BudgetCommentListViewModel({required this.item}) {
    deleteCommand = Command0<void>(_deleteSelected);
  }

  final BudgetCommentRepository _commentRepository =
      getIt<BudgetCommentRepository>();

  final CustomerInfo item;

  late final Command0<void> deleteCommand;

  List<ObservationBudget> observation = <ObservationBudget>[];

  final Set<String> _selectedIds = <String>{};

  /// Assinante usa a lista de comentários (criar com IA / selecionar);
  /// free mantém o modal antigo.
  bool get hasCommentLibrary => getIt<CheckCommentLibraryAccessUsecase>()();

  /// Quantos comentários há na lista; erro conta como 0 (abre o criar).
  Future<int> getLibraryCount() async {
    final result = await getIt<CommentLibraryRepository>().fetchComments();
    return result is Ok<List<CommentLibraryModel>> ? result.value.length : 0;
  }

  Future<bool> loadComments() async {
    final result = await _commentRepository.fetchComments(item.id!);
    if (result is Ok<List<ObservationBudget>>) {
      observation = List<ObservationBudget>.from(result.value);
      _selectedIds.retainWhere((id) => observation.any((o) => o.id == id));
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Usado pelo modal antigo (não assinante) ---
  Future<bool> addComment(String text) async {
    final result = await _commentRepository.addComment(item.id!, text);
    if (result is Ok<void>) {
      await loadComments();
      return true;
    }
    return false;
  }

  Future<bool> updateComment(ObservationBudget updateObservation) async {
    final result = await _commentRepository.updateComment(
      item.id!,
      updateObservation,
    );
    if (result is Ok<void>) {
      await loadComments();
      return true;
    }
    return false;
  }

  // --- Seleção / remoção em massa ---
  bool get selectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool isSelected(ObservationBudget o) => _selectedIds.contains(o.id);

  bool get allSelected =>
      observation.isNotEmpty && observation.every(isSelected);

  void toggleSelect(ObservationBudget o) {
    final id = o.id;
    if (id == null || id.isEmpty || deleteCommand.running) return;
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  /// Marca para remoção (ação "Excluir" do modal de detalhe).
  void markForDelete(ObservationBudget o) {
    if (!isSelected(o)) toggleSelect(o);
  }

  void selectAll() {
    if (allSelected) {
      _selectedIds.clear();
    } else {
      _selectedIds.addAll(observation.map((o) => o.id).whereType<String>());
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<Result<void>> _deleteSelected() async {
    final selected = observation.where(isSelected).toList();
    final result = await _commentRepository.deleteComments(item.id!, selected);
    if (result is Ok<void>) {
      _selectedIds.clear();
      await loadComments();
    }
    return result;
  }

  @override
  void dispose() {
    deleteCommand.dispose();
    super.dispose();
  }
}
