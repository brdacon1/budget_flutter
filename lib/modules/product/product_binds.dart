import 'package:get_it/get_it.dart';
import 'package:oflite/modules/product/data/datasource/product_price_remote_datasource.dart';
import 'package:oflite/modules/product/data/repository/product_price_repository_impl.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';

void registerProductDependencies(GetIt sl) {
  sl.registerLazySingleton<ProductPriceRemoteDataSource>(
    () => ProductPriceRemoteDataSource(),
  );
  sl.registerLazySingleton<ProductPriceRepository>(
    () => ProductPriceRepositoryImpl(sl<ProductPriceRemoteDataSource>()),
  );
}
