import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/services/convert_coin.dart';

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
  final ConvertCoin moneyConvert;
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

  Future<void> _handleButton() async {
    if (_processing) return;
    setState(() => _processing = true);
    await widget.onButtonPressed();
    if (mounted) {
      setState(() => _processing = false);
    }
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
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            return Card(
              color: const Color(0xFFF5F5F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
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
                onTap: widget.onItemTap == null
                    ? null
                    : () => widget.onItemTap!(item, index),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                    if (item.QTD != null)
                      Text(
                        item.QTD.toString(),
                        style: GoogleFonts.heebo(
                          color: AppBottomModal.grayColor,
                          letterSpacing: 0.5,
                          fontSize: 10.0,
                        ),
                      ),
                    if (item.PRECO != null)
                      Text(
                        widget.moneyConvert.convertFromDouble(item.PRECO!),
                        style: GoogleFonts.heebo(
                          color: AppBottomModal.grayColor,
                          letterSpacing: 0.5,
                          fontSize: 10.0,
                        ),
                      ),
                  ],
                ),
                trailing: GestureDetector(
                  onTap: () {
                    widget.onRemove(item, index);
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.close,
                    color: AppBottomModal.grayColor,
                    size: 23.0,
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
