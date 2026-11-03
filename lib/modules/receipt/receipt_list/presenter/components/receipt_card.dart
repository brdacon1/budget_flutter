import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 12, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        height: 46.0,
                        child: _ActionButton(
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
                        child: _ActionButton(
                          icon: Icons.open_in_new_rounded,
                          label: ReceiptPtString.openLabel,
                          onPressed: onOpen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: whiteColor.withOpacity(0.08),
          foregroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 16, color: whiteColor),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
