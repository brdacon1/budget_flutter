import 'package:oflite/injection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    required this.deleteItens,
    required this.moneyConvert,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<ItemsBudget> deleteItens;
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