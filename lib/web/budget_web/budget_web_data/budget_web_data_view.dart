import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';
import 'package:oflite/services/convert_coin.dart';
import 'components/budget_web_approve_button.dart';
import 'components/budget_web_comments_section.dart';
import 'components/budget_web_data_section.dart';
import 'components/budget_web_items_section.dart';
import '../budget_web_items/components/budget_web_items_total_bar.dart';
import '../budget_web_items/components/modals/budget_web_approval_modal_widget.dart';

/// Tab "Meus dados" do orçamento Web — agora centraliza **tudo** o que o
/// cliente precisa ver num único scroll:
///
/// 1. Dados do cliente/orçamento (contato, informações, endereço) — read-only,
///    reutilizando as mesmas labels do app mobile.
/// 2. Lista de itens do orçamento (seção colapsável, com busca + cards
///    expansíveis por item).
/// 3. Lista de comentários/observações (seção colapsável, read-only).
///
/// No rodapé fixo (sempre visível durante o scroll) ficam:
/// - A **barra de totais** (full-width, sem padding lateral) — não rola mais
///   junto com a lista.
/// - O botão **Aprovar/Reprovar**, que reflete o status atual (verde =
///   aprovado, vermelho = reprovado) e abre o modal de aprovação. Sem padding
///   sob o botão (encosta na borda inferior).
///
/// A antiga aba "Itens" foi removida: sua lista agora vive aqui, abaixo dos
/// dados do cliente, como pedido na spec.
class BudgetWebDataView extends StatefulWidget {
  const BudgetWebDataView({
    super.key,
    required this.budget,
    required this.items,
    required this.observations,
    required this.moneyConvert,
    required this.totalProducts,
    required this.totalServices,
    required this.totalBudget,
    required this.onApprove,
    required this.onPreview,
  });

  final CustomerInfo budget;
  final List<ItemsBudget> items;
  final List<ObservationPdf> observations;
  final ConvertCoin moneyConvert;
  final double totalProducts;
  final double totalServices;
  final double totalBudget;

  /// Callback de aprovação/reprovação (gravado pelo ViewModel do orçamento).
  final ValueChanged<String> onApprove;

  /// Callback que abre a pré-visualização do PDF do orçamento (vai para a
  /// aba "PDF"). Torna a pré-visualização acessível sem sair da aba
  /// "Meus dados".
  final VoidCallback onPreview;

  @override
  State<BudgetWebDataView> createState() => _BudgetWebDataViewState();
}

class _BudgetWebDataViewState extends State<BudgetWebDataView> {
  final TextEditingController _searchController = TextEditingController();

  List<ItemsBudget> get _filteredItems {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((i) => (i.DESCRICAO ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // Layout em coluna: conteúdo rolável em cima, painel fixo (totais +
      // botão de aprovar) embaixo. Assim a barra de totais fica sempre visível
      // (não rola junto) e o botão encosta na borda inferior, sem padding.
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              children: [
                BudgetWebDataSection(
                  title: BudgetWebStrings.sectionContact,
                  icon: Icons.person_outlined,
                  rows: [
                    BudgetWebDataRow(BudgetWebStrings.labelCustomerName,
                        _orEmpty(widget.budget.customerName)),
                    BudgetWebDataRow(
                        BudgetWebStrings.labelPhone, _orEmpty(widget.budget.phone)),
                  ],
                ),
                BudgetWebDataSection(
                  title: BudgetWebStrings.sectionInfo,
                  icon: Icons.request_page_outlined,
                  rows: [
                    BudgetWebDataRow(BudgetWebStrings.labelStatus,
                        _orEmpty(widget.budget.status)),
                    BudgetWebDataRow(
                        BudgetWebStrings.labelDate, _orEmpty(widget.budget.data)),
                    BudgetWebDataRow(BudgetWebStrings.labelNumber,
                        _orEmpty(widget.budget.id)),
                  ],
                ),
                BudgetWebDataSection(
                  title: BudgetWebStrings.sectionAddress,
                  icon: Icons.location_on_outlined,
                  rows: [
                    BudgetWebDataRow(
                        BudgetWebStrings.labelCep, _orEmpty(widget.budget.zip)),
                    BudgetWebDataRow(BudgetWebStrings.labelStreet,
                        _orEmpty(widget.budget.street)),
                    BudgetWebDataRow(
                        BudgetWebStrings.labelCity, _orEmpty(widget.budget.city)),
                    BudgetWebDataRow(BudgetWebStrings.labelNeighborhood,
                        _orEmpty(widget.budget.neighborhood)),
                  ],
                ),
                BudgetWebItemsSection(
                  items: _filteredItems,
                  moneyConvert: widget.moneyConvert,
                  searchController: _searchController,
                  onSearchChanged: () => setState(() {}),
                ),
                BudgetWebCommentsSection(observations: widget.observations),
                // Botão de pré-visualização do PDF: leva o cliente direto
                // para a aba "PDF", onde o orçamento é mostrado no navegador
                // (além do download). Exclusivo da versão Web.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: whiteColor,
                        side: const BorderSide(color: buttonColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      onPressed: widget.onPreview,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        BudgetWebStrings.pdfPreviewButton,
                        style: GoogleFonts.heebo(
                          color: whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Painel fixo do rodapé: totais (full-width) + botão de aprovar
          // (full-width, encostado na borda inferior, sem padding sob ele).
          Material(
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BudgetWebItemsTotalBar(
                  moneyConvert: widget.moneyConvert,
                  totalProducts: widget.totalProducts,
                  totalServices: widget.totalServices,
                  totalBudget: widget.totalBudget,
                ),
                BudgetWebApproveButton(
                  status: widget.budget.status,
                  onPressed: () async {
                    await showBudgetWebApprovalModal(
                      context,
                      onSelect: (status) => widget.onApprove(status),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orEmpty(String? v) {
    final s = v?.toString();
    if (s == null || s.isEmpty || s == 'null') return '-';
    return s;
  }
}
