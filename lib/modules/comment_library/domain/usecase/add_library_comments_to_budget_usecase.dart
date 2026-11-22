import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Copia os comentários escolhidos no modal-lista para `OBSERVACAO` do
/// orçamento. É cópia: editar a biblioteca depois não muda o orçamento.
/// Para no primeiro erro (os anteriores já ficaram gravados).
class AddLibraryCommentsToBudgetUsecase {
  final BudgetCommentRepository _budgetComments;

  AddLibraryCommentsToBudgetUsecase(this._budgetComments);

  Future<Result<void>> call(
    String budgetId,
    List<CommentLibraryModel> comments,
  ) async {
    for (final c in comments) {
      final result = await _budgetComments.addComment(budgetId, c.text);
      if (result is Error<void>) return result;
    }
    return const Result.ok(null);
  }
}
