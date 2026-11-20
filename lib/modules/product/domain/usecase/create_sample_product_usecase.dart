import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/domain/repository/product_price_repository.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Cria um produto de exemplo na lista de preço de um usuário recém-cadastrado,
/// para ele já conseguir selecionar um item da lista no primeiro orçamento.
///
/// Chamar **só na criação da conta**, depois de `createDefaultUserData`
/// (o repositório usa o usuário da sessão). Falha não deve bloquear o
/// cadastro: quem chama ignora o erro.
class CreateSampleProductUseCase {
  const CreateSampleProductUseCase(this._productRepository);

  final ProductPriceRepository _productRepository;

  Future<Result<String?>> call() {
    return _productRepository.addProduct(
      ProductPriceModel(
        // value persistido fixo (Regra Zero de i18n); só a descrição traduz.
        categoria: ItemCategory.products.value,
        descricao: ProductPtString.sampleProductDescription,
        preco: 100,
        qtd: 1,
        total: 100,
        medida: ProductPtString.sampleProductMeasure,
      ),
    );
  }
}
