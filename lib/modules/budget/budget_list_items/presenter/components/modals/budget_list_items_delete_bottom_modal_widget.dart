import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';

/// Bottom modal para confirmar a remoção de itens marcados do orçamento.
///
/// É um [StatefulWidget] porque mantém uma **cópia local** da lista de itens a
/// remover: ao tocar no "X" de cada item, ele é retirado da cópia local (com
/// `setState`) e o callback [onRemove] notifica o ViewModel — assim a lista do
/// modal atualiza **em tempo real** sem depender de reconstrução externa.
/// O botão "EXCLUIR ITENS" dispara [onConfirm] (que apaga no Firebase) e fecha
/// o modal.
class BudgetListItemsDeleteBottomModalWidget extends StatefulWidget {
  const BudgetListItemsDeleteBottomModalWidget({
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
  State<BudgetListItemsDeleteBottomModalWidget> createState() =>
      _BudgetListItemsDeleteBottomModalWidgetState();
}

class _BudgetListItemsDeleteBottomModalWidgetState
    extends State<BudgetListItemsDeleteBottomModalWidget> {
  late final List<ItemsBudget> _items;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Cópia local — a UI reconstrói a partir dela, garantindo atualização
    // em tempo real ao remover um item via "X".
    _items = List<ItemsBudget>.from(widget.deleteItens);
  }

  void _removeItem(ItemsBudget item) {
    widget.onRemove(item);
    setState(() {
      _items.remove(item);
    });
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    final displayAlert = DisplayAlert();
    final alertDisplayLoading = LoadingEvent();
    await alertDisplayLoading.alertLoading(context);
    try {
      await widget.onConfirm();
      alertDisplayLoading.closeLoading(context);
      if (context.mounted) {
        await displayAlert.notification(
            context, 'Tudo Certo!', 'Orçamentos removidos com sucesso!');
      }
    } catch (e) {
      alertDisplayLoading.closeLoading(context);
      if (context.mounted) {
        await displayAlert.notificationError(
            context, 'Erro!', 'Ocorreu um erro ao remover os orçamentos.');
      }
    }
    if (mounted) {
      setState(() => _processing = false);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Remover produtos',
      buttonLabel: _processing ? 'Aguarde...' : 'EXCLUIR ITENS',
      onButtonPressed: _processing ? () {} : _confirm,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: _items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum item selecionado.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.heebo(
                    color: AppBottomModal.grayColor,
                    fontSize: 14,
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _DeleteItemCard(
                    item: _items[index],
                    moneyConvert: widget.moneyConvert,
                    onRemove: () => _removeItem(_items[index]),
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
