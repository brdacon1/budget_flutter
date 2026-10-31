import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/web_budget/strings/budget_web_strings.dart';
import 'package:oflite/modules/web_budget/budget_web/budget_web_data/budget_web_data_view.dart';
import 'budget_web_budget_view_model.dart';

/// Orçamento liberado no fluxo Web — tela única "Meus dados".
///
/// A antiga aba "Itens" foi removida (a lista de itens vive dentro de "Meus
/// dados"). A antiga aba "PDF" também foi **removida**: o `<iframe>`
/// embutido só mostrava a primeira página de forma confiável; agora o
/// botão "Pré-visualizar PDF" da tela "Meus dados" abre o PDF no
/// visualizador nativo do navegador em uma **nova aba** (scroll/zoom entre
/// todas as páginas), reutilizando a mesma regra de geração do PDF
/// (`BudgetWebPdfViewModel`/`PdfGenerateUseCase`). O `BudgetWebBudgetViewModel`
/// carrega o orçamento, itens, titular e observações uma única vez.
class BudgetWebBudgetView extends StatefulWidget {
  const BudgetWebBudgetView({
    super.key,
    required this.enderecoNumero,
    required this.ownerUid,
    required this.token,
  });

  final String enderecoNumero;
  final String ownerUid;
  final String token;

  @override
  State<BudgetWebBudgetView> createState() => _BudgetWebBudgetViewState();
}

class _BudgetWebBudgetViewState extends State<BudgetWebBudgetView> {
  late final BudgetWebBudgetViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetWebBudgetViewModel(
      ownerUid: widget.ownerUid,
      enderecoNumero: widget.enderecoNumero,
      token: widget.token,
    );
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
          if (_viewModel.loading) {
            return const Center(
              child: CircularProgressIndicator(color: buttonColor),
            );
          }
          if (_viewModel.error != null || _viewModel.budget == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _viewModel.error ?? BudgetWebStrings.blockedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }
          return BudgetWebDataView(
            budget: _viewModel.budget!,
            items: _viewModel.items,
            observations: _viewModel.observations,
            owner: _viewModel.owner!,
            token: widget.token,
            moneyConvert: _viewModel.moneyConvert,
            totalProducts: _viewModel.totalProducts,
            totalServices: _viewModel.totalServices,
            totalBudget: _viewModel.totalBudget,
            onApprove: (status) => _viewModel.updateStatus(context, status),
          );
        },
      ),
    );
  }
}