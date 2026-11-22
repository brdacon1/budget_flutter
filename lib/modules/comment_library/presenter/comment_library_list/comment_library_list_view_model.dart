import 'package:flutter/widgets.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado da tela de gestão da biblioteca de comentários: busca, seleção
/// para remoção em lote (mesmo fluxo da lista de preço).
class CommentLibraryListViewModel extends ChangeNotifier {
  CommentLibraryListViewModel() {
    deleteCommand = Command0<void>(_deleteSelected);
  }

  final CommentLibraryRepository _repo = getIt<CommentLibraryRepository>();

  final TextEditingController searchController = TextEditingController();

  late final Command0<void> deleteCommand;

  List<CommentLibraryModel> _all = <CommentLibraryModel>[];
  bool isLoading = false;
  bool loadFailed = false;

  final Set<String> _selectedIds = <String>{};

  List<CommentLibraryModel> get found {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.text.toLowerCase().contains(q),
        )
        .toList();
  }

  void onSearchChanged() => notifyListeners();

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _repo.fetchComments();
    if (result is Ok<List<CommentLibraryModel>>) {
      _all = List<CommentLibraryModel>.of(result.value);
      _selectedIds.retainWhere((id) => _all.any((c) => c.id == id));
      loadFailed = false;
    } else {
      loadFailed = true;
    }
    isLoading = false;
    notifyListeners();
  }

  bool get selectionMode => _selectedIds.isNotEmpty;
  int get selectedCount => _selectedIds.length;
  bool isSelected(CommentLibraryModel c) => _selectedIds.contains(c.id);

  bool get allFilteredSelected {
    final items = found;
    return items.isNotEmpty && items.every(isSelected);
  }

  void toggleSelect(CommentLibraryModel c) {
    final id = c.id;
    if (id == null) return;
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  void selectAllFiltered() {
    final ids = found.map((c) => c.id).whereType<String>();
    if (allFilteredSelected) {
      _selectedIds.removeAll(ids);
    } else {
      _selectedIds.addAll(ids);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<Result<void>> _deleteSelected() async {
    final selected = _all.where(isSelected).toList();
    final result = await _repo.deleteComments(selected);
    if (result is Ok<void>) {
      _selectedIds.clear();
      await load();
    }
    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    deleteCommand.dispose();
    super.dispose();
  }
}
