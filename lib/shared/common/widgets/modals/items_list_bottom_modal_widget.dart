import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';

/// Modal inferior com uma lista de itens (carrinho/exclusão) removíveis.
///
/// Substitui os antigos `AlertDialog` de "Carrinho de produtos" e "Remover
/// produtos". Bottom modal com fundo branco, textos cinza máximo, lista de
/// itens (cada um com botão de remover) e botão de ação no rodapé no padrão
/// dos botões do projeto. A regra de negócio (adicionar/remover do Firebase)
/// continua em quem chama, via callbacks.
class ItemsListBottomModalWidget extends StatefulWidget {
  const ItemsListBottomModalWidget({
    super.key,
    required this.title,
    required this.items,
    required this.moneyConvert,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.onRemove,
    this.onItemTap,
  });

  final String title;
  final List<ItemsBudget> items;
  final ConvertCoinRepository moneyConvert;
  final String buttonLabel;
  final Future<void> Function() onButtonPressed;
  final void Function(ItemsBudget item, int index) onRemove;
  final Future<void> Function(ItemsBudget item, int index)? onItemTap;

  @override
  State<ItemsListBottomModalWidget> createState() =>
      _ItemsListBottomModalWidgetState();
}

class _ItemsListBottomModalWidgetState extends State<ItemsListBottomModalWidget> {
  bool _processing = false;
  late List<ItemsBudget> _items;

  @override
  void initState() {
    super.initState();
    _items = List<ItemsBudget>.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant ItemsListBottomModalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length ||
        !identical(widget.items, oldWidget.items)) {
      _items = List<ItemsBudget>.from(widget.items);
    }
  }

  Future<void> _handleButton() async {
    if (_processing) return;
    setState(() => _processing = true);
    await widget.onButtonPressed();
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  String _formatQuantity(double? qtd) {
    if (qtd == null) return '0';
    if (qtd == qtd.truncateToDouble()) {
      return qtd.toInt().toString();
    }
    return qtd.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: widget.title,
      buttonLabel: _processing ? 'Aguarde...' : widget.buttonLabel,
      onButtonPressed: _processing ? () {} : _handleButton,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: _items.isEmpty
            ? SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
          child: Center(
            child: Text(
              ProductPtString.cartEmptyLabel,
              style: GoogleFonts.heebo(
                color: AppBottomModal.grayColor,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final double priceUnit = item.PRECO ?? 0.0;
            final double qtd = item.QTD ?? 0.0;
            final double totalPrice = priceUnit * qtd;

            return Card(
              color: const Color(0xFFF5F5F5),
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Color(0xFFDDE2E5), width: 1.2),
              ),
              child: InkWell(
                onTap: widget.onItemTap == null
                    ? null
                    : () => widget.onItemTap!(item, index),
                borderRadius: BorderRadius.circular(10.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Lado Esquerdo: Descrição, Quantidade no meio e Categoria embaixo
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
                      // Lado Direito: Total Calculado, Preço Unitário e Lixeira Grande
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.moneyConvert.convertFromDouble(totalPrice),
                            style: GoogleFonts.heebo(
                              color: AppBottomModal.grayColor,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.moneyConvert.convertFromDouble(priceUnit)} un',
                            style: GoogleFonts.heebo(
                              color: AppBottomModal.grayColor.withOpacity(0.7),
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              widget.onRemove(item, index);
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
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
              ),
            );
          },
        ),
      ),
    );
  }
}