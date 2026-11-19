import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:oflite/modules/receipt/presenter/receipt_creator/components/receipt_creator_form.dart';
import 'package:oflite/modules/receipt/presenter/receipt_creator/components/receipt_creator_summary_card.dart';
import 'package:oflite/modules/receipt/presenter/receipt_creator/receipt_creator_view_model.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_form_save_button.dart';
import 'package:oflite/shared/common/widgets/form/app_keyboard_dismiss_bar.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

/// Tela de criação/edição de recibo.
///
/// `StatefulWidget` que cria o [ReceiptCreatorViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + formulário + botão) e delega
/// as ações ao ViewModel. Os blocos visuais repetidos vivem em `components/`
/// ([ReceiptCreatorSummaryCard], [ReceiptCreatorForm]) e em
/// `shared/common/widgets/form/` ([AppFormSaveButton]).
///
/// Como o [Receipt] é imutável (padrão canônico, seção 10 do SDD), o recibo
/// recém-criado é propagado às abas irmãs via [onReceiptCreated] (callback do
/// [ReceiptTabViewModel]), em vez de mutar um objeto compartilhado.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Componentes recebem dados + callbacks, nunca o VM inteiro.
/// - `BuildContext` recebido por parâmetro nos métodos do VM (não guardado).
/// - Nenhum texto visível ao usuário como literal — todos via
///   [ReceiptPtString].
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
      item: widget.item,
      onReceiptCreated: widget.onReceiptCreated,
    );
  }

  @override
  void didUpdateWidget(ReceiptCreatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.id != widget.receipt.id ||
        oldWidget.receipt.valorTotal != widget.receipt.valorTotal) {
      _viewModel.updateReceipt(widget.receipt);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AnimatedBuilder(
          animation: _viewModel,
          // LayoutBuilder: reconstrói quando a área muda com o teclado.
          builder:
              (context, _) => LayoutBuilder(
                builder: (context, _) {
                  final receipt = _viewModel.receipt;
                  // Teclado aberto: esconde o botão e mostra a barra de fechar
                  // teclado (§17.8).
                  // Lê do View (não do MediaQuery): a Scaffold das abas já consome o
                  // viewInsets, então MediaQuery aqui sempre retorna 0.
                  final keyboardOpen = View.of(context).viewInsets.bottom > 0;
                  return Column(
                    children: <Widget>[
                      Expanded(
                        // SafeArea: o conteúdo rolado não passa por baixo da status bar.
                        child: SafeArea(
                          bottom: false,
                          child: Stack(
                            children: <Widget>[
                              ListView(
                                // Espaço para o último campo não ficar sob o botão.
                                padding: const EdgeInsets.only(bottom: 96),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                children: <Widget>[
                                  AppHeaderSecondTitle(
                                    titlePage: _viewModel.titlePage,
                                    secondTitle: ReceiptPtString.subtitle,
                                    onBack: () => Navigator.pop(context, true),
                                    insideSafeArea: true,
                                    isBottomPadding: false,
                                  ),
                                  if (_viewModel.isEditing)
                                    ReceiptCreatorSummaryCard(
                                      id: receipt.id ?? '',
                                      date: receipt.data ?? '-',
                                      total: receipt.valorTotal ?? 0,
                                    ),
                                  ReceiptCreatorForm(
                                    descricaoController:
                                        _viewModel.descricaoText,
                                    descricaoNode: _viewModel.descricaoNode,
                                    descricaoError: _viewModel.descricaoError,
                                    onSubmitted: () => _viewModel.save(context),
                                  ),
                                ],
                              ),
                              if (!keyboardOpen)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      8,
                                      20,
                                      16,
                                    ),
                                    child: AppFormSaveButton(
                                      label: _viewModel.nameButton,
                                      highlighted: _viewModel.isDirty,
                                      loading: _viewModel.saving,
                                      onPressed: () => _viewModel.save(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (keyboardOpen)
                        AppKeyboardDismissBar(
                          label: ReceiptPtString.closeKeyboard,
                        ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}
