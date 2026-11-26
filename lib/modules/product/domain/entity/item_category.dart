import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';

/// Categoria do item (produto/serviço).
///
/// [value] é o texto gravado no Firestore — fixo, NUNCA traduzir (Regra Zero,
/// `.pi/I18N_STRINGS_PLAN.md`). [label] é o texto exibido na tela (pt/en).
enum ItemCategory {
  products('Produtos'),
  services('Serviços');

  final String value;
  const ItemCategory(this.value);

  String get label => switch (this) {
    ItemCategory.products => ProductPtString.categoryProducts,
    ItemCategory.services => ProductPtString.categoryServices,
  };

  /// Lê o valor do Firestore aceitando legados: `'Products'`/`'Services'`
  /// (gravados por aparelhos em inglês desde o commit 389430b), sem acento e
  /// `'1'`. Desconhecido → `null` (não regravar).
  static ItemCategory? fromValue(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'produtos':
      case 'produto':
      case 'products':
      case 'product':
      case '1':
        return ItemCategory.products;
      case 'serviços':
      case 'servicos':
      case 'serviço':
      case 'servico':
      case 'services':
      case 'service':
        return ItemCategory.services;
    }
    return null;
  }
}
