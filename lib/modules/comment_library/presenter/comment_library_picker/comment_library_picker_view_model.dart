import 'package:flutter/widgets.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/add_library_comments_to_budget_usecase.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado do modal-lista de comentários (= picker da lista de preço):
/// busca, seleção na ordem do toque e [addAllCommand] que copia para o
/// orçamento.
class CommentLibraryPickerViewModel extends ChangeNotifier {
  CommentLibraryPickerViewModel({required this.budgetId}) {
    addAllCommand = Command0<void>(_addAll);
  }

  final String budgetId;

  final CommentLibraryRepository _repo = getIt<CommentLibraryRepository>();
  final AddLibraryCommentsToBudgetUsecase _addComments =
      getIt<AddLibraryCommentsToBudgetUsecase>();

  final TextEditingController searchController = TextEditingController();

  late final Command0<void> addAllCommand;

  List<CommentLibraryModel> _all = <CommentLibraryModel>[];
  bool isLoading = true;

  /// Selecionados por id, na ordem do toque.
  final Map<String, CommentLibraryModel> _selected = {};

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

  int get selectedCount => _selected.length;
  bool isSelected(CommentLibraryModel c) => _selected.containsKey(c.id);

  void onSearchChanged() => notifyListeners();

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _repo.fetchComments();
    _all =
        result is Ok<List<CommentLibraryModel>>
            ? List<CommentLibraryModel>.of(result.value)
            : <CommentLibraryModel>[];
    isLoading = false;
    notifyListeners();
  }

  void toggle(CommentLibraryModel c) {
    final id = c.id;
    if (id == null || addAllCommand.running) return;
    if (_selected.remove(id) == null) _selected[id] = c;
    notifyListeners();
  }

  Future<Result<void>> _addAll() =>
      _addComments(budgetId, _selected.values.toList());

  @override
  void dispose() {
    searchController.dispose();
    addAllCommand.dispose();
    super.dispose();
  }
}
