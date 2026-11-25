import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/components/product_price_field.dart';
import 'package:oflite/modules/product/presenter/product_price_creator/product_price_creator_view_model.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/enums/product_price_field_enum.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/option_bottom_modal_widget.dart';

/// Modal inferior de criação/edição de produto ou serviço (lista de preço).
///
/// Antes era uma tela cheia (`Scaffold` próprio com header escuro); agora segue
/// o **padrão de bottom modal** do app, reaproveitando a base visual
/// [AppBottomModal] (header com título + botão fechar, drag handle, botão de
/// ação no rodapé e acompanhamento do teclado). Mesmo virando modal, é um
/// **modal complexo** (vários campos, seleção de categoria, fluxo de
/// salvar/atualizar), então **mantém View + ViewModel** — o
/// [ProductPriceCreatorViewModel] (`extends ChangeNotifier`) é quem detém o
/// estado; a View só reage via `AnimatedBuilder` e delega `save(context)`.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - `StatefulWidget` que cria o VM em `initState` e o descarta em `dispose`.
/// - Reconstrução via `AnimatedBuilder(animation: _viewModel, ...)` — sem
///   `setState`.
/// - `BuildContext` recebido por parâmetro nos métodos (não guardado como
///   campo do VM).
/// - Componentes (`ProductPriceField`) recebem dados + callbacks, nunca o VM
///   inteiro.
/// - Campos no padrão visual dos bottom modals (fundo branco, borda cinza),
///   igual a `singup_field.dart`.
/// - Abertura/fechamento do modal fica por conta de quem chama
///   (`showProductPriceCreatorBottomModal`), mantendo a navegação desacoplada
///   da regra.
class ProductPriceCreatorView extends StatefulWidget {
  final ProductPriceModel item;
  final bool fromListItem;

  const ProductPriceCreatorView({
    super.key,
    required this.item,
    this.fromListItem = false,
  });

  @override
  State<ProductPriceCreatorView> createState() =>
      _ProductPriceCreatorViewState();
}

class _ProductPriceCreatorViewState extends State<ProductPriceCreatorView> {
  late final ProductPriceCreatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPriceCreatorViewModel(
      item: widget.item,
      fromListItem: widget.fromListItem,
    );
    _viewModel.saveCommand.addListener(_onSaveChanged);
  }

  void _onSaveChanged() {
    final cmd = _viewModel.saveCommand;
    if (cmd.completed) {
      AlertSnackBar.success(
        context,
        ProductPtString.doneTitle,
        _viewModel.successMessage,
      );
      Navigator.pop(context, true);
    } else if (cmd.error) {
      AlertSnackBar.error(
        context,
        ProductPtString.errorTitle,
        _viewModel.errorMessage ?? ProductPtString.addError,
      );
    }
  }

  Future<void> _selectCategory() async {
    final value = await showOptionBottomModal(
      context,
      title: ProductPtString.selectCategoryTitle,
      values: ItemCategory.values.map((c) => c.label).toList(),
    );
    if (value != null) _viewModel.setCategory(value);
  }

  @override
  void dispose() {
    _viewModel.saveCommand.removeListener(_onSaveChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, _viewModel.saveCommand]),
      builder: (context, _) {
        final saving = _viewModel.saveCommand.running;

        return AppBottomModal(
          title: _viewModel.titlePage,
          buttonLabel: _viewModel.nameButton,
          buttonLoading: saving,
          onButtonPressed: _viewModel.saveCommand.execute,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                ProductPriceField(
                  controller: _viewModel.categoriaText,
                  hintText: ProductPtString.categoryHint,
                  icon: Icons.list_alt,
                  readOnly: true,
                  onTap: _selectCategory,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: AppBottomModal.grayColor,
                  ),
                ),
                const SizedBox(height: 16),
                ProductPriceField(
                  controller: _viewModel.unidadeText,
                  hintText: ProductPtString.unitHint,
                  icon: Icons.analytics_outlined,
                  onTap:
                      () =>
                          _viewModel.selectField(ProductPriceFieldType.unidade),
                ),
                const SizedBox(height: 16),
                ProductPriceField(
                  controller: _viewModel.priceController,
                  hintText: ProductPtString.priceHint,
                  icon: Icons.price_change_outlined,
                  keyboardType: TextInputType.number,
                  onTap:
                      () => _viewModel.selectField(ProductPriceFieldType.preco),
                ),
                const SizedBox(height: 16),
                Visibility(
                  visible: _viewModel.fieldVisible,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ProductPriceField(
                        controller: _viewModel.qtdText,
                        hintText: ProductPtString.qtyHint,
                        icon: Icons.calculate_outlined,
                        keyboardType: TextInputType.number,
                        onTap:
                            () => _viewModel.selectField(
                              ProductPriceFieldType.qtd,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                ProductPriceField(
                  controller: _viewModel.descricaoText,
                  hintText: ProductPtString.descriptionHint,
                  icon: Icons.edit_note,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  onTap:
                      () => _viewModel.selectField(
                        ProductPriceFieldType.descricao,
                      ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper que abre o [ProductPriceCreatorView] como modal bottom sheet.
///
/// Segue o mesmo formato dos demais helpers de modal do app
/// (`showSingUpBottomModal`, `showAppBottomModal`): `isScrollControlled` para
/// acompanhar o teclado e fundo transparente (a base [AppBottomModal] desenha
/// o card branco arredondado). Retorna `true` quando o item é salvo, para que
/// a tela de origem recarregue a lista.
Future<bool?> showProductPriceCreatorBottomModal(
  BuildContext context, {
  required ProductPriceModel item,
  bool fromListItem = false,
}) {
  return showAppModal<bool>(
    context,
    builder:
        (context) =>
            ProductPriceCreatorView(item: item, fromListItem: fromListItem),
  );
}
