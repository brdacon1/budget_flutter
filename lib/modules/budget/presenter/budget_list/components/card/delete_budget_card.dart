import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/common/utils/get_budget_status_color.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

class DeleteItemCard extends StatelessWidget {
  const DeleteItemCard({
    super.key,
    required this.item,
    required this.onRemove
  });

  final CustomerInfo item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final statusConfig = GetBudgetStatusColor.get(item.status!);

    return Card(
      color: const Color(0xFFF5F5F5),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente: ${item.customerName}',
                    style: GoogleFonts.heebo(
                      color: AppBottomModal.grayColor,
                      letterSpacing: 0.5,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nº orçamento: ${item.id}',
                    style: GoogleFonts.heebo(
                      color: AppBottomModal.grayColor,
                      letterSpacing: 0.5,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Criado em: ${item.data}',
                    style: GoogleFonts.heebo(
                      color: AppBottomModal.grayColor,
                      letterSpacing: 0.5,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.bgLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusConfig.icon,
                        size: 14,
                        color: statusConfig.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.status!.toUpperCase(),
                        style: GoogleFonts.heebo(
                          color: statusConfig.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                      size: 28.0,
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