import 'package:material_ui/material_ui.dart';

import 'presenter/product_price_list/product_price_list_view.dart';

enum ProductRoute { productPriceList, productPriceCreator }

extension ProductRouteExtension on ProductRoute {
  String get path {
    switch (this) {
      case ProductRoute.productPriceList:
        return '/product/list';
      case ProductRoute.productPriceCreator:
        return '/product/create';
    }
  }
}

/// ProductPriceListView é a tela de gestão da lista de preço. A seleção de
/// itens para o orçamento é o modal `ProductPricePickerView`.
/// ProductPriceCreatorView é exibido como bottom modal — navegação
/// interna via `MaterialPageRoute`.
final Map<String, WidgetBuilder> productRoutes = {
  ProductRoute.productPriceList.path: (_) => const ProductPriceListView(),
};
