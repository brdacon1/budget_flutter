import 'package:oflite/injection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/budget_list_items/presenter/components/card/delete_items_card.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';

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
    required this.deleteItems,
    required this.moneyConvert,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<ItemsBudget> deleteItems;
  final ConvertCoinRepository moneyConvert;
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
    _items = List<ItemsBudget>.from(widget.deleteItems);
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
    final displayAlert = getIt<DisplayAlertRepository>();
    final alertDisplayLoading = getIt<LoadingEventRepository>();
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
                  return DeleteItemCard(
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

