import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';

/// Decide se o app deve perguntar o ramo de atuação ao entrar.
///
/// Pergunta só quem ainda não respondeu **e** ainda não montou a lista de
/// preço (no máximo o produto de exemplo do cadastro) — conta antiga com lista
/// própria nunca é interrompida.
class ShouldAskSegmentUsecase {
  const ShouldAskSegmentUsecase(this._userRepository, this._productRepository);

  final UserRepository _userRepository;
  final ProductPriceRepository _productRepository;

  Future<bool> call() async {
    final user = _userRepository.selectUser.value;
    if (user == null || user.segment != null) return false;
    return await _productRepository.getProductCount() <= 1;
  }
}
