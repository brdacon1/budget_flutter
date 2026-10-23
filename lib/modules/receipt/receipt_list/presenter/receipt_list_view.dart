import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'components/receipt_card.dart';
import 'components/receipt_list_header.dart';
import 'receipt_list_view_model.dart';

/// Tela de **lista de recibos**.
///
/// `StatefulWidget` que cria o [ReceiptListViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + lista + FAB) e delega as ações
/// (carregar, excluir, abrir, criar) ao ViewModel. Os blocos visuais
/// repetidos vivem em `components/` ([ReceiptListHeader], [ReceiptCard]).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Componentes recebem dados + callbacks, nunca o VM inteiro.
/// - `BuildContext` recebido por parâmetro nos métodos do VM (não guardado).
/// - `RefreshIndicator.onRefresh` aponta para `_viewModel.refresh`.
/// - `ListView.builder` com `itemCount`/`itemBuilder` lendo o VM.
/// - `FloatingActionButton` delega ação ao VM.
class ReceiptListView extends StatefulWidget {
  final CustomerInfo item;
  const ReceiptListView({super.key, required this.item});

  @override
  State<ReceiptListView> createState() => _ReceiptListView();
}

class _ReceiptListView extends State<ReceiptListView> {
  late final ReceiptListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReceiptListViewModel(item: widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
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
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ReceiptListHeader(
                onBack: () => Navigator.pop(context, true),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.cyan[50],
                  backgroundColor: bgColor,
                  onRefresh: _viewModel.refresh,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                        bottom: 150, left: 15, right: 15, top: 10),
                    itemCount: _viewModel.foundPayment.length,
                    itemBuilder: (context, index) {
                      return ReceiptCard(
                        item: _viewModel.foundPayment[index],
                        moneyConvert: _viewModel.moneyConvert,
                        onDelete: () =>
                            _viewModel.deleteReceipt(context, index),
                        onOpen: () =>
                            _viewModel.openReceipt(context, index),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _viewModel.addReceipt(context),
        backgroundColor: buttonColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
