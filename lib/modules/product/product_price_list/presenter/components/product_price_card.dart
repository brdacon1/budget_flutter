import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/product/product_price/data/model/product_price_model.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';

/// Card de item da lista de preço.
///
/// Component `Stateless` puro — recebe o item ([ProductPriceModel]), o
/// conversor de moeda, os flags de visibilidade dos checkboxes
/// (`checkBoxAppear` para exclusão no leading, `checkBoxProductVisible` para
/// carrinho no trailing, `fromMenu` que esconde o checkbox de carrinho) e os
/// callbacks (`onLongPress`, `onTap`, `onToggleSelectProduct`,
/// `onToggleDelete`). Não conhece o ViewModel nem services.
///
/// O estado dos checkboxes é lido do próprio `item` (`item.checkBox` /
/// `item.selectProduct`), que é imutável e reconstruído a cada mudança pelo
/// `AnimatedBuilder` da View.
class ProductPriceCard extends StatelessWidget {
  const ProductPriceCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.fromMenu,
    required this.checkBoxAppear,
    required this.checkBoxProductVisible,
    required this.onLongPress,
    required this.onTap,
    required this.onToggleSelectProduct,
    required this.onToggleDelete,
  });

  final ProductPriceModel item;
  final ConvertCoin moneyConvert;
  final bool fromMenu;
  final bool checkBoxAppear;
  final bool checkBoxProductVisible;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onToggleSelectProduct;
  final VoidCallback onToggleDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${item.descricao}',
                  maxLines: 2,
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${item.categoria}',
                style: const TextStyle(
                  color: whiteColor,
                  letterSpacing: 0,
                  fontSize: 12.0,
                ),
              ),
              Text(
                moneyConvert.convertFromDouble(item.preco ?? 0),
                style: const TextStyle(
                  color: whiteColor,
                  letterSpacing: 0,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
        onLongPress: onLongPress,
        onTap: onTap,
        trailing: Transform.scale(
          scale: 1.7,
          child: Visibility(
            visible: !fromMenu && checkBoxProductVisible,
            child: Checkbox(
              side: const BorderSide(color: whiteColor),
              checkColor: bgColor,
              activeColor: whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              value: item.selectProduct ?? false,
              onChanged: (bool? newValue) => onToggleSelectProduct(),
            ),
          ),
        ),
        leading: Transform.scale(
          scale: 1.6,
          child: Visibility(
            visible: checkBoxAppear,
            child: Checkbox(
              side: const BorderSide(color: whiteColor),
              checkColor: bgColor,
              activeColor: whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              value: item.checkBox ?? false,
              onChanged: (bool? newValue) => onToggleDelete(),
            ),
          ),
        ),
      ),
    );
  }
}
