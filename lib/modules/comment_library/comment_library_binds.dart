import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/data/datasource/comment_library_remote_datasource.dart';
import 'package:oflite/modules/comment_library/data/repository/comment_library_repository_impl.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/add_library_comments_to_budget_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/generate_comment_name_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/save_library_comment_usecase.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';

/// Biblioteca de comentários (somente assinantes).
void registerCommentLibraryDependencies(GetIt sl) {
  sl.registerLazySingleton<CommentLibraryRemoteDatasource>(
    CommentLibraryRemoteDatasource.new,
  );
  sl.registerLazySingleton<CommentLibraryRepository>(
    () => CommentLibraryRepositoryImpl(
      sl<CommentLibraryRemoteDatasource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerFactory<CheckCommentLibraryAccessUsecase>(
    () => CheckCommentLibraryAccessUsecase(sl<UserRepository>()),
  );
  sl.registerFactory<GenerateCommentNameUsecase>(
    () => GenerateCommentNameUsecase(sl<GenerateAiTextUsecase>()),
  );
  sl.registerFactory<ImproveCommentTextUsecase>(
    () => ImproveCommentTextUsecase(sl<GenerateAiTextUsecase>()),
  );
  sl.registerFactory<SaveLibraryCommentUsecase>(
    () => SaveLibraryCommentUsecase(
      sl<CommentLibraryRepository>(),
      sl<GenerateCommentNameUsecase>(),
      sl<BudgetCommentRepository>(),
    ),
  );
  sl.registerFactory<AddLibraryCommentsToBudgetUsecase>(
    () => AddLibraryCommentsToBudgetUsecase(sl<BudgetCommentRepository>()),
  );
}
