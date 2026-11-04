import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

class DeleteItemCard extends StatelessWidget {
  const DeleteItemCard({super.key,
    required this.item,
    required this.moneyConvert,
    required this.onRemove,
  });

  final ItemsBudget item;
  final ConvertCoinRepository moneyConvert;
  final VoidCallback onRemove;

  String _formatQuantity(double? qtd) {
    if (qtd == null) return '0';
    if (qtd == qtd.truncateToDouble()) {
      return qtd.toInt().toString();
    }
    return qtd.toString();
  }

  @override
  Widget build(BuildContext context) {
    final double priceUnit = item.PRECO ?? 0.0;
    final double qtd = item.QTD ?? 0.0;
    final double totalPrice = priceUnit * qtd;

    return Card(
      color: const Color(0xFFF5F5F5),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.DESCRICAO ?? 'Sem descrição',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.heebo(
                      color: AppBottomModal.grayColor,
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quantidade: ${_formatQuantity(item.QTD)}',
                    style: GoogleFonts.heebo(
                      color: AppBottomModal.grayColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.CATEGORIA != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.CATEGORIA.toString().toUpperCase(),
                        style: GoogleFonts.heebo(
                          color: AppBottomModal.grayColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  moneyConvert.convertFromDouble(totalPrice),
                  style: GoogleFonts.heebo(
                    color: AppBottomModal.grayColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${moneyConvert.convertFromDouble(priceUnit)} un',
                  style: GoogleFonts.heebo(
                    color: AppBottomModal.grayColor.withOpacity(0.7),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 30.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}