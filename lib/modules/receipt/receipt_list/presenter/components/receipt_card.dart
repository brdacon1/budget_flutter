import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
import 'package:oflite/shared/common/constants/constants.dart';

/// Card de recibo (ExpansionTileCard) da lista de recibos.
///
/// Component `Stateless` puro — recebe o item, o utilitário de moeda e os
/// callbacks de excluir/abrir. **Não** acessa services nem o ViewModel
/// inteiro (segue o padrão do SDD: dados + callbacks). Espelha fielmente o
/// layout original da View, inclusive os rótulos "Excluir"/"Abrir".
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.item,
    required this.moneyConvert,
    required this.onDelete,
    required this.onOpen,
  });

  final Receipt item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                height: 46.0,
                child: ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: ReceiptPtString.deleteLabel,
                  onPressed: onDelete,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                height: 46.0,
                child: ActionButton(
                  icon: Icons.open_in_new_rounded,
                  label: ReceiptPtString.openLabel,
                  onPressed: onOpen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.receipt_long_rounded, color: whiteColor),
          ),
          title: Text(
            item.descricao!,
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${ReceiptPtString.totalValueLabel}'
            '${moneyConvert.convertFromDouble(item.valorTotal!)}',
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(
              thickness: 1.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  '${ReceiptPtString.dateLabel}${item.data}',
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  '${ReceiptPtString.quantityLabel}${item.id}',
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }
}

