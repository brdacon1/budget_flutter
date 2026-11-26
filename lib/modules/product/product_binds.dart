import 'package:get_it/get_it.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/product/data/datasource/product_price_remote_datasource.dart';
import 'package:oflite/modules/product/data/repository/product_price_repository_impl.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/modules/product/domain/usecase/create_sample_product_usecase.dart';
import 'package:oflite/modules/product/domain/usecase/generate_product_catalog_usecase.dart';
import 'package:oflite/modules/product/domain/usecase/save_product_catalog_usecase.dart';
import 'package:oflite/modules/product/domain/usecase/should_ask_segment_usecase.dart';

void registerProductDependencies(GetIt sl) {
  sl.registerLazySingleton<ProductPriceRemoteDataSource>(
    () => ProductPriceRemoteDataSource(),
  );
  sl.registerLazySingleton<ProductPriceRepository>(
    () => ProductPriceRepositoryImpl(
      sl<ProductPriceRemoteDataSource>(),
      sl<UserRepository>(),
    ),
  );
  sl.registerFactory<CreateSampleProductUseCase>(
    () => CreateSampleProductUseCase(sl<ProductPriceRepository>()),
  );
  sl.registerFactory<ShouldAskSegmentUsecase>(
    () => ShouldAskSegmentUsecase(
      sl<UserRepository>(),
      sl<ProductPriceRepository>(),
    ),
  );
  sl.registerFactory<GenerateProductCatalogUsecase>(
    () => GenerateProductCatalogUsecase(sl<GenerateAiTextUsecase>()),
  );
  sl.registerFactory<SaveProductCatalogUsecase>(
    () => SaveProductCatalogUsecase(
      sl<ProductPriceRepository>(),
      sl<UserRepository>(),
    ),
  );
}
