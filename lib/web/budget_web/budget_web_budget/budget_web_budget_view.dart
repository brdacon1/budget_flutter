import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/web/budget_web/budget_web_data/budget_web_data_view.dart';
import 'package:oflite/web/budget_web/budget_web_pdf/budget_web_pdf_view.dart';
import 'budget_web_budget_view_model.dart';

/// Orçamento liberado no fluxo Web — abas "Meus dados" e "PDF".
///
/// A antiga aba "Itens" foi **removida**: a lista de itens (e a de
/// comentários) agora vive dentro da aba "Meus dados", logo abaixo dos
/// dados do cliente, em seções colapsáveis. O `BudgetWebBudgetViewModel`
/// carrega o orçamento, itens, titular e observações uma única vez; as
/// abas consomem esses dados.
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
  int _currentIndex = 0;

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
          switch (_currentIndex) {
            case 0:
              return BudgetWebDataView(
                budget: _viewModel.budget!,
                items: _viewModel.items,
                observations: _viewModel.observations,
                moneyConvert: _viewModel.moneyConvert,
                totalProducts: _viewModel.totalProducts,
                totalServices: _viewModel.totalServices,
                totalBudget: _viewModel.totalBudget,
                onApprove: (status) =>
                    _viewModel.updateStatus(context, status),
                onPreview: () => setState(() => _currentIndex = 1),
              );
            case 1:
              return BudgetWebPdfView(
                items: _viewModel.items,
                customer: _viewModel.budget!,
                owner: _viewModel.owner!,
                observations: _viewModel.observations,
                token: widget.token,
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: secondaryColor),
        child: BottomNavigationBar(
          selectedItemColor: Colors.cyan[50],
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Meus dados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.picture_as_pdf),
              label: 'PDF',
            ),
          ],
        ),
      ),
    );
  }
}
