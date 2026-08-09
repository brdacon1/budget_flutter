import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';

class BudgetListItemsDeleteDialog extends StatelessWidget {
  const BudgetListItemsDeleteDialog({
    super.key,
    required this.deleteItens,
    required this.moneyConvert,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<ItemsBudget> deleteItens;
  final ConvertCoin moneyConvert;
  final void Function(ItemsBudget item) onRemove;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Remover produtos',
      buttonLabel: 'EXCLUIR ITENS',
      onButtonPressed: () async {
        var displayAlert = DisplayAlert();
        var alertDisplayLoading = LoadingEvent();
        await alertDisplayLoading.alertLoading(context);
        try {
          await onConfirm();
          alertDisplayLoading.closeLoading(context);
          await displayAlert.notification(
              context, 'Tudo Certo!', 'Orçamentos removidos com sucesso!');
        } catch (e) {
          alertDisplayLoading.closeLoading(context);
          await displayAlert.notificationError(
              context, 'Erro!', 'Ocorreu um erro ao remover os orçamentos.');
        }
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
              moneyConvert: moneyConvert,
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
  const _DeleteItemCard({
    required this.item,
    required this.moneyConvert,
    required this.onRemove,
  });

  final ItemsBudget item;
  final ConvertCoin moneyConvert;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Text(
          item.DESCRICAO ?? '',
          maxLines: 1,
          style: GoogleFonts.heebo(
            color: AppBottomModal.grayColor,
            letterSpacing: 0.5,
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.CATEGORIA.toString(),
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                letterSpacing: 0.5,
                fontSize: 10.0,
              ),
            ),
            Text(
              moneyConvert.convertFromDouble(item.PRECO!),
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                letterSpacing: 0.5,
                fontSize: 10.0,
              ),
            ),
            Text(
              item.QTD.toString(),
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                letterSpacing: 0.5,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
        trailing: Transform.scale(
          scale: 1.4,
          child: GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              color: AppBottomModal.grayColor,
              size: 20.0,
            ),
          ),
        ),
      ),
    );
  }
}
