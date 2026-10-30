import 'package:flutter/material.dart';
import 'product_price_list/presenter/product_price_list_view.dart';

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

/// ProductPriceListView aceita argumentos opcionais (modo picker, fromMenu);
/// a rota expõe a versão sem argumentos (útil para navegação do menu).
/// ProductPriceCreatorView é exibido como bottom modal — navegação
/// interna via `MaterialPageRoute`.
final Map<String, WidgetBuilder> productRoutes = {
  ProductRoute.productPriceList.path: (_) => const ProductPriceListView(),
};
