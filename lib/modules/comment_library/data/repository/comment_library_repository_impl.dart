import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/comment_library/data/datasource/comment_library_remote_datasource.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class CommentLibraryRepositoryImpl implements CommentLibraryRepository {
  final CommentLibraryRemoteDatasource _remote;
  final UserRepository _userRepository;

  CommentLibraryRepositoryImpl(this._remote, this._userRepository);

  Future<Result<T>> _withUser<T>(Future<T> Function(String uid) run) async {
    final uid = _userRepository.selectUser.value?.user;
    if (uid == null || uid.isEmpty) {
      return Result.error(Exception('User not authenticated'));
    }
    try {
      return Result.ok(await run(uid));
    } on Exception catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<List<CommentLibraryModel>>> fetchComments() => _withUser(
    (uid) async => [
      for (final m in await _remote.getComments(uid))
        CommentLibraryModel.fromMap(m),
    ],
  );

  @override
  Future<Result<String>> addComment(CommentLibraryModel comment) =>
      _withUser((uid) => _remote.addComment(uid, comment.toMap()));

  @override
  Future<Result<void>> updateComment(CommentLibraryModel comment) => _withUser(
    (uid) => _remote.updateComment(uid, comment.id!, comment.toMap()),
  );

  @override
  Future<Result<void>> deleteComments(List<CommentLibraryModel> comments) =>
      _withUser(
        (uid) => _remote.deleteComments(uid, [
          for (final c in comments)
            if (c.id != null) c.id!,
        ]),
      );
}
