import 'package:flutter/foundation.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class ProductPriceRepository extends ChangeNotifier {
  List<ProductPriceModel> get products;

  Future<Result<List<ProductPriceModel>>> fetchProducts({bool forceRefresh = false});
  Future<Result<String?>> addProduct(ProductPriceModel product);
  Future<Result<void>> updateProduct(ProductPriceModel product);
  Future<Result<void>> deleteProduct(String id);
  Future<Result<void>> deleteProducts(List<String> ids);
  Future<int> getProductCount();
}
