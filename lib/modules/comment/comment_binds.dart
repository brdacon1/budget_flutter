import 'package:get_it/get_it.dart';
import 'package:oflite/modules/comment/data/datasource/comment_remote_datasource.dart';
import 'package:oflite/modules/comment/data/repository/comment_repository_impl.dart';
import 'package:oflite/modules/comment/domain/repository/comment_repository.dart';

void registerCommentDependencies(GetIt sl) {
  sl.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSource(),
  );
  sl.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(sl<CommentRemoteDataSource>()),
  );
}
