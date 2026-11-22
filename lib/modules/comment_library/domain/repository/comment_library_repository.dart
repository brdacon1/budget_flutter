import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Contrato da biblioteca de comentários do usuário.
abstract class CommentLibraryRepository {
  Future<Result<List<CommentLibraryModel>>> fetchComments();

  /// Devolve o id criado.
  Future<Result<String>> addComment(CommentLibraryModel comment);

  Future<Result<void>> updateComment(CommentLibraryModel comment);

  Future<Result<void>> deleteComments(List<CommentLibraryModel> comments);
}
