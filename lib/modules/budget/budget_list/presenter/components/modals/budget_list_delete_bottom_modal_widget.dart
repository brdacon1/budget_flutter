import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/modules/budget/budget_list/presenter/components/card/delete_budget_card.dart';
import 'package:oflite/shared/common/utils/get_budget_status_color.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';

/// Bottom modal para confirmar a remoção de orçamentos marcados.
///
/// É um [StatefulWidget] porque mantém uma **cópia local** da lista de
/// orçamentos a remover: ao tocar no "X" de cada item, ele é retirado da
/// cópia local (com `setState`) e o callback [onRemove] notifica o ViewModel
/// — assim a lista do modal atualiza **em tempo real**. O botão "EXCLUIR
/// TODOS" dispara [onConfirm] e fecha o modal.
class BudgetListDeleteBottomModalWidget extends StatefulWidget {
  const BudgetListDeleteBottomModalWidget({
    super.key,
    required this.deleteItens,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<CustomerInfo> deleteItens;
  final void Function(CustomerInfo item) onRemove;
  final Future<void> Function() onConfirm;

  @override
  State<BudgetListDeleteBottomModalWidget> createState() =>
      _BudgetListDeleteBottomModalWidgetState();
}

class _BudgetListDeleteBottomModalWidgetState
    extends State<BudgetListDeleteBottomModalWidget> {
  late final List<CustomerInfo> _items;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // Cópia local — a UI reconstrói a partir dela, garantindo atualização
    // em tempo real ao remover um item via "X".
    _items = List<CustomerInfo>.from(widget.deleteItens);
  }

  void _removeItem(CustomerInfo item) {
    widget.onRemove(item);
    setState(() {
      _items.remove(item);
    });
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    await widget.onConfirm();
    if (mounted) {
      setState(() => _processing = false);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Remover orçamentos',
      buttonLabel: _processing ? 'Aguarde...' : 'EXCLUIR TODOS',
      onButtonPressed: _processing ? () {} : _confirm,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: _items.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nenhum orçamento selecionado.',
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
                    onRemove: () => _removeItem(_items[index]),
                  );
                },
              ),
      ),
    );
  }
}


