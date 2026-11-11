import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_list/components/card/product_price_delete_item_card.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Bottom modal para confirmar a remoção de itens marcados da lista de preço.
///
/// É um [StatefulWidget] porque mantém uma **cópia local** da lista de itens a
/// remover: ao tocar no "X" de cada item, ele é retirado da cópia local (com
/// `setState`) e o callback [onRemove] notifica o ViewModel — assim a lista do
/// modal atualiza **em tempo real** sem depender de reconstrução externa.
/// O botão "EXCLUIR ITENS" dispara [onConfirm] (que apaga no Firebase) e fecha
/// o modal.
class ProductPriceListDeleteBottomModalWidget extends StatefulWidget {
  const ProductPriceListDeleteBottomModalWidget({
    super.key,
    required this.deleteItems,
    required this.moneyConvert,
    required this.onRemove,
    required this.onConfirm,
  });

  final List<ProductPriceModel> deleteItems;
  final ConvertCoinRepository moneyConvert;
  final void Function(ProductPriceModel item) onRemove;
  final Future<void> Function() onConfirm;

  @override
  State<ProductPriceListDeleteBottomModalWidget> createState() =>
      _ProductPriceListDeleteBottomModalWidgetState();
}

class _ProductPriceListDeleteBottomModalWidgetState
    extends State<ProductPriceListDeleteBottomModalWidget> {
  late final List<ProductPriceModel> _items;
  bool _processing = false;

  final displayAlert = getIt<DisplayAlertRepository>();
  final alertDisplayLoading = getIt<LoadingEventRepository>();

  @override
  void initState() {
    super.initState();
    _items = List<ProductPriceModel>.from(widget.deleteItems);
  }

  void _removeItem(ProductPriceModel item) {
    widget.onRemove(item);
    setState(() {
      _items.remove(item);
    });
  }

  Future<void> _confirm() async {
    if (_processing) return;
    setState(() => _processing = true);
    await _openLoad(isOpen: true);
    try {
      await widget.onConfirm();
      await _openLoad(isOpen: false);
      await _notification(
        isSuccess: true,
        primaryText: ProductPtString.doneTitle,
        message: ProductPtString.deleteSuccess,
      );
    } catch (e) {
      await _openLoad(isOpen: false);
      await _notification(
        isSuccess: false,
        primaryText: ProductPtString.errorTitle,
        message: ProductPtString.deleteError,
      );
    }
    if (mounted) {
      setState(() => _processing = false);
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _notification({
    required bool isSuccess,
    required String primaryText,
    required String message,
  }) async {
    if (context.mounted) {
      if (isSuccess) {
        await displayAlert.notification(context, primaryText, message);
      } else {
        await displayAlert.notificationError(context, primaryText, message);
      }
    }
  }

  Future<void> _openLoad({required bool isOpen}) async {
    if (context.mounted) {
      if (isOpen) {
        await alertDisplayLoading.alertLoading(context);
      } else {
        alertDisplayLoading.closeLoading(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: ProductPtString.deleteListTitle,
      buttonLabel: _processing ? 'Aguarde...' : ProductPtString.deleteButton,
      onButtonPressed: _processing ? () {} : _confirm,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child:
            _items.isEmpty
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
                    return ProductPriceDeleteItemCard(
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
