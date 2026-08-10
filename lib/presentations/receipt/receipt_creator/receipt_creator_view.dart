import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/receipt.dart';
import 'components/receipt_creator_form.dart';
import 'components/receipt_creator_header.dart';
import 'components/receipt_creator_save_button.dart';
import 'receipt_creator_view_model.dart';

/// Tela de criação/edição de recibo.
///
/// `StatefulWidget` que cria o [ReceiptCreatorViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + formulário + botão) e delega
/// as ações ao ViewModel. Os blocos visuais repetidos vivem em `components/`
/// ([ReceiptCreatorHeader], [ReceiptCreatorForm], [ReceiptCreatorSaveButton]).
///
/// Como o [Receipt] é imutável (padrão canônico, seção 10 do SDD), o recibo
/// recém-criado é propagado às abas irmãs via [onReceiptCreated] (callback do
/// [ReceiptTabViewModel]), em vez de mutar um objeto compartilhado.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Componentes recebem dados + callbacks, nunca o VM inteiro.
/// - `BuildContext` recebido por parâmetro nos métodos do VM (não guardado).
/// - Nenhum texto visível ao usuário como literal — todos via
///   [ReceiptStrings].
class ReceiptCreatorView extends StatefulWidget {
  final Receipt receipt;
  final CustomerInfo item;

  /// Notifica o [ReceiptTabViewModel] de que um novo recibo foi criado, para
  /// que as abas irmãs (Pagamentos/PDF) recebam o recibo atualizado.
  final ValueChanged<Receipt>? onReceiptCreated;

  const ReceiptCreatorView({
    super.key,
    required this.item,
    required this.receipt,
    this.onReceiptCreated,
  });

  @override
  State<ReceiptCreatorView> createState() => _ReceiptCreatorView();
}

class _ReceiptCreatorView extends State<ReceiptCreatorView> {
  late final ReceiptCreatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReceiptCreatorViewModel(
      receipt: widget.receipt,
      onReceiptCreated: widget.onReceiptCreated,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double we = MediaQuery.of(context).size.width;
    final double he = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: SizedBox(
              width: we,
              height: he,
              child: Column(
                children: <Widget>[
                  ReceiptCreatorHeader(
                    titlePage: _viewModel.titlePage,
                    onBack: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        ReceiptCreatorForm(
                          descricaoController: _viewModel.descricaoText,
                          idController: _viewModel.idText,
                          dataController: _viewModel.dataText,
                          fieldVisible: _viewModel.fieldVisible,
                          subtitle: _viewModel.formSubtitle,
                          selectedField: _viewModel.selectedField,
                          onSelectField: _viewModel.selectField,
                        ),
                        ReceiptCreatorSaveButton(
                          label: _viewModel.nameButton,
                          onPressed: () => _viewModel.save(context),
                        ),
                        SizedBox(height: he * 0.3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
