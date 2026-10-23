import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/strings/receipt_strings.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/modules/payment/payment_list/presenter/payment_list_view.dart';
import 'package:oflite/modules/pdf/pdf_receipt/presenter/pdf_receipt_view.dart';
import 'package:oflite/modules/receipt/receipt_creator/presenter/receipt_creator_view.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'receipt_tab_view_model.dart';

/// Tela de **abas de recibo** (Recibo / Pagamentos / PDF).
///
/// `StatefulWidget` que cria o [ReceiptTabViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe o `Scaffold` (body = filho da aba atual +
/// `BottomNavigationBar`) e delega a troca de aba ao ViewModel. O
/// [Receipt] atual vive no ViewModel; quando a aba de criação persiste um
/// novo recibo, ele chama `updateReceipt`, e as abas irmãs são reconstruídas
/// com o recibo atualizado.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - `BuildContext` não guardado como campo do VM.
/// - Nenhum texto visível ao usuário como literal — todos via
///   [ReceiptStrings].
class ReceiptTabView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt receipt;
  const ReceiptTabView({super.key, required this.item, required this.receipt});

  @override
  State<ReceiptTabView> createState() => _ReceiptTabView();
}

class _ReceiptTabView extends State<ReceiptTabView> {
  late final ReceiptTabViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReceiptTabViewModel(receipt: widget.receipt);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> labels = _viewModel.tabLabels;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          // Construídos a cada rebuild para capturar o [Receipt] mais recente
          // do ViewModel (atualizado pela aba de criação via [updateReceipt]).
          final Receipt receipt = _viewModel.receipt;
          switch (_viewModel.currentIndex) {
            case 0:
              return ReceiptCreatorView(
                item: widget.item,
                receipt: receipt,
                onReceiptCreated: _viewModel.updateReceipt,
              );
            case 1:
              return PaymentListView(item: widget.item, receipt: receipt);
            case 2:
              return PdfReceiptView(item: widget.item, receipt: receipt);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: secondaryColor,
        ),
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return BottomNavigationBar(
              selectedItemColor: Colors.cyan[50],
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                  fontSize: 11.0, fontWeight: FontWeight.bold),
              unselectedItemColor: Colors.grey,
              onTap: _viewModel.onTabTapped,
              currentIndex: _viewModel.currentIndex,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: labels[0],
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.payments_outlined),
                  label: labels[1],
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: labels[2],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
