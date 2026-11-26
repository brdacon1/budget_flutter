import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/entity/business_segment.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Grava a lista revisada pelo usuário e o ramo escolhido.
///
/// O ramo só é gravado depois dos itens: se algo falhar, o usuário pode tentar
/// de novo — itens já salvos (mesma descrição) não são duplicados.
class SaveProductCatalogUsecase {
  const SaveProductCatalogUsecase(
    this._productRepository,
    this._userRepository,
  );

  final ProductPriceRepository _productRepository;
  final UserRepository _userRepository;

  Future<Result<void>> call(
    BusinessSegment segment,
    List<ProductPriceModel> items,
  ) async {
    final existing = await _productRepository.fetchProducts(forceRefresh: true);
    final names = <String>{
      if (existing is Ok<List<ProductPriceModel>>)
        for (final p in existing.value) (p.descricao ?? '').toLowerCase(),
    };
    for (final item in items) {
      if (names.contains((item.descricao ?? '').toLowerCase())) continue;
      final added = await _productRepository.addProduct(item);
      if (added is Error<String?>) return Result.error(added.error);
    }
    return _saveSegment(segment);
  }

  /// "Agora não": registra que o ramo já foi perguntado.
  Future<Result<void>> skip() => _saveSegment(BusinessSegment.none);

  Future<Result<void>> _saveSegment(BusinessSegment segment) {
    final user = _userRepository.selectUser.value;
    if (user == null) {
      return Future.value(Result.error(Exception('User not authenticated')));
    }
    user.segment = segment.value;
    return _userRepository.updateUser(user).then((r) {
      if (r is Error<void>) user.segment = null;
      return r;
    });
  }
}
