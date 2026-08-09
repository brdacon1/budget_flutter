import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/enums/product_price_field_enum.dart';
import 'package:oflite/common/strings/product_strings.dart';
import 'package:oflite/presentations/product/model/product_price_model.dart';

import 'components/product_price_creator_header.dart';
import 'components/product_price_field.dart';
import 'product_price_creator_view_model.dart';

/// Tela de criação/edição de produto ou serviço (lista de preço).
///
/// `StatefulWidget` que cria o [ProductPriceCreatorViewModel] em `initState`
/// e o descarta em `dispose`. A reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nunca `setState`**. A
/// View só monta a estrutura (header + card de formulário + botão) e delega
/// toda a regra de negócio/persistência ao VM (`save`).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Dado imutável recebido por construtor ([ProductPriceModel item]).
/// - `dispose` chama `_viewModel.dispose()` **antes** de `super.dispose()`.
/// - Componentes (`ProductPriceCreatorHeader`, `ProductPriceField`) recebem
///   dados + callbacks, nunca o VM inteiro.
/// - Enum de seleção de campo em `lib/common/enums/`.
/// - Textos visíveis via `lib/common/strings/product_strings.dart`.
class ProductPriceCreatorView extends StatefulWidget {
  final ProductPriceModel item;

  const ProductPriceCreatorView({super.key, required this.item});

  @override
  State<ProductPriceCreatorView> createState() => _ProductPriceCreatorView();
}

class _ProductPriceCreatorView extends State<ProductPriceCreatorView> {
  late final ProductPriceCreatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductPriceCreatorViewModel(item: widget.item);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: SizedBox(
          width: we,
          height: he,
          child: Column(
            children: <Widget>[
              ProductPriceCreatorHeader(
                title: _viewModel.titlePage,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _viewModel,
                  builder: (context, _) {
                    return ListView(
                      children: <Widget>[
                        _formCard(context),
                        _saveButton(context),
                        SizedBox(height: he * 0.3),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card expansível com os campos do formulário.
  Widget _formCard(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    final subtitle = _viewModel.isEditing
        ? ProductStrings.formCardSubtitleEdit
        : ProductStrings.formCardSubtitleCreate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.shopping_cart_outlined, color: whiteColor),
          ),
          title: Text(
            ProductStrings.formCardTitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          children: <Widget>[
            ProductPriceField(
              controller: _viewModel.categoriaText,
              hintText: ProductStrings.categoryHint,
              icon: Icons.list_alt,
              readOnly: true,
              onTap: () => _viewModel.selectCategory(context),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_outlined,
                  color: whiteColor),
            ),
            SizedBox(height: he * 0.02),
            ProductPriceField(
              controller: _viewModel.unidadeText,
              hintText: ProductStrings.unitHint,
              icon: Icons.analytics_outlined,
              onTap: () => _viewModel.selectField(ProductPriceFieldType.unidade),
            ),
            SizedBox(height: he * 0.02),
            ProductPriceField(
              controller: _viewModel.priceController,
              hintText: ProductStrings.priceHint,
              icon: Icons.price_change_outlined,
              keyboardType: TextInputType.number,
              onTap: () => _viewModel.selectField(ProductPriceFieldType.preco),
            ),
            SizedBox(height: he * 0.02),
            Visibility(
              visible: _viewModel.fieldVisible,
              child: ProductPriceField(
                controller: _viewModel.qtdText,
                hintText: ProductStrings.qtyHint,
                icon: Icons.calculate_outlined,
                keyboardType: TextInputType.number,
                onTap: () => _viewModel.selectField(ProductPriceFieldType.qtd),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: ProductPriceField(
                controller: _viewModel.descricaoText,
                hintText: ProductStrings.descriptionHint,
                icon: Icons.edit_note,
                keyboardType: TextInputType.multiline,
                maxLines: 50,
                widthFactor: 0.80,
                onTap: () =>
                    _viewModel.selectField(ProductPriceFieldType.descricao),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botão de salvar/atualizar — delega a ação ao VM.
  Widget _saveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: TextButton(
        onPressed: () => _viewModel.save(context),
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          padding:
              const EdgeInsets.symmetric(vertical: 15.0, horizontal: 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          _viewModel.nameButton,
          style: GoogleFonts.heebo(
            color: Colors.black,
            letterSpacing: 0.5,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
