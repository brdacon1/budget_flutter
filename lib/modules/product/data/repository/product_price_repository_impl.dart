import 'package:oflite/modules/product/data/datasource/product_price_remote_datasource.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class ProductPriceRepositoryImpl extends ProductPriceRepository {
  final ProductPriceRemoteDataSource _remote;
  ProductPriceRepositoryImpl(this._remote);

  List<ProductPriceModel> _products = [];

  @override
  List<ProductPriceModel> get products => List.unmodifiable(_products);

  @override
  Future<Result<List<ProductPriceModel>>> fetchProducts(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _products.isNotEmpty) {
      return Result.ok(_products);
    }
    try {
      final raw = await _remote.getProducts();
      _products = raw
          .map((e) => ProductPriceModel.fromJson(e)
              .copyWith(id: e['id'] as String?, checkBox: false, selectProduct: false))
          .toList();
      notifyListeners();
      return Result.ok(_products);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<String?>> addProduct(ProductPriceModel product) async {
    try {
      final map = product.toJson()..['COLOR'] = 'false';
      final docRef = await _remote.addProduct(map);
      final id = docRef.id;
      _products.add(product.copyWith(id: id));
      notifyListeners();
      return Result.ok(id);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductPriceModel product) async {
    try {
      if (product.id == null) {
        return Result.error(Exception('Product id is null'));
      }
      await _remote.updateProduct(product.id!, product.toJson()..['COLOR'] = 'false');
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        notifyListeners();
      }
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(String id) async {
    try {
      await _remote.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProducts(List<String> ids) async {
    try {
      for (final id in ids) {
        await _remote.deleteProduct(id);
      }
      _products.removeWhere((p) => ids.contains(p.id));
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<int> getProductCount() async {
    try {
      final raw = await _remote.getProducts();
      return raw.length;
    } catch (_) {
      return 0;
    }
  }
}
