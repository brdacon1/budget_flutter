import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/entity/comment_library_exceptions.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/generate_comment_name_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Cria ou atualiza um comentário da biblioteca.
///
/// - [name] vazio/`null` → nome gerado pela IA (com fallback).
///   Na edição, a View manda `null` quando o texto mudou e o usuário não
///   mexeu no nome, para o nome acompanhar o assunto.
/// - [budgetId] (criação a partir do orçamento, como o `fromListItem` da
///   lista de preço) → também grava o texto em `OBSERVACAO` do orçamento.
class SaveLibraryCommentUsecase {
  static const maxTextLength = 1000;

  final CommentLibraryRepository _repo;
  final GenerateCommentNameUsecase _generateName;
  final BudgetCommentRepository _budgetComments;

  SaveLibraryCommentUsecase(
    this._repo,
    this._generateName,
    this._budgetComments,
  );

  Future<Result<CommentLibraryModel>> call({
    String? id,
    required String text,
    String? name,
    String? budgetId,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return Result.error(const CommentTextEmptyException());
    if (body.length > maxTextLength) {
      return Result.error(const CommentTextTooLongException(maxTextLength));
    }

    final givenName = name?.trim() ?? '';
    final comment = CommentLibraryModel(
      id: id,
      text: body,
      name: givenName.isNotEmpty ? givenName : await _generateName(body),
    );

    if (id != null) {
      final updated = await _repo.updateComment(comment);
      return switch (updated) {
        Ok() => Result.ok(comment),
        Error(:final error) => Result.error(error),
      };
    }

    final added = await _repo.addComment(comment);
    if (added is Error<String>) return Result.error(added.error);
    final saved = comment.copyWith(id: (added as Ok<String>).value);

    if (budgetId != null) {
      final linked = await _budgetComments.addComment(budgetId, body);
      if (linked is Error<void>) {
        return Result.error(CommentSavedButNotLinkedException(saved.id!));
      }
    }
    return Result.ok(saved);
  }
}
