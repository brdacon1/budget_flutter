import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/models/customer_info.dart';

class BudgetListDeleteDialog extends StatelessWidget {
  const BudgetListDeleteDialog({
    super.key,
    required this.deleteItens,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<CustomerInfo> deleteItens;
  final void Function(CustomerInfo item) onRemove;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Remover orçamentos',
      buttonLabel: 'EXCLUIR TODOS',
      onButtonPressed: () async {
        await onConfirm();
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: deleteItens.length,
          itemBuilder: (context, index) {
            return _DeleteItemCard(
              item: deleteItens[index],
              onRemove: () {
                onRemove(deleteItens[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _DeleteItemCard extends StatelessWidget {
  const _DeleteItemCard({required this.item, required this.onRemove});

  final CustomerInfo item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Text(
          'Cliente: ${item.customerName}',
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            letterSpacing: 0.5,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nº orçamento: ${item.id}',
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                letterSpacing: 0.5,
                fontSize: 12.0,
              ),
            ),
            Text(
              'Status: ${item.status}',
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                letterSpacing: 0.5,
                fontSize: 12.0,
              ),
            ),
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
        trailing: GestureDetector(
          onTap: onRemove,
          child: const Icon(
            Icons.close,
            color: AppBottomModal.grayColor,
            size: 23.0,
          ),
        ),
      ),
    );
  }
}
