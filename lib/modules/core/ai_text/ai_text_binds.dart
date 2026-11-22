import 'package:get_it/get_it.dart';
import 'package:oflite/modules/core/ai_text/data/datasource/ai_text_local_datasource.dart';
import 'package:oflite/modules/core/ai_text/data/datasource/ai_text_remote_datasource.dart';
import 'package:oflite/modules/core/ai_text/data/repository/ai_text_repository_impl.dart';
import 'package:oflite/modules/core/ai_text/domain/repository/ai_text_repository.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';

/// Registra a geração de texto simples com IA (Gemini).
void registerAiTextDependencies(GetIt sl) {
  sl.registerLazySingleton<AiTextRemoteDatasource>(AiTextRemoteDatasource.new);
  sl.registerLazySingleton<AiTextLocalDatasource>(AiTextLocalDatasource.new);
  sl.registerLazySingleton<AiTextRepository>(
    () => AiTextRepositoryImpl(
      sl<AiTextRemoteDatasource>(),
      sl<AiTextLocalDatasource>(),
    ),
  );
  sl.registerFactory<GenerateAiTextUsecase>(
    () => GenerateAiTextUsecase(sl<AiTextRepository>()),
  );
}
