import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:oflite/services/convert_coin.dart';
import 'components/budget_web_approve_button.dart';
import 'components/budget_web_comments_section.dart';
import 'components/budget_web_data_section.dart';
import 'components/budget_web_items_section.dart';
import '../budget_web_items/components/budget_web_items_total_bar.dart';
import '../budget_web_items/components/modals/budget_web_approval_modal_widget.dart';
import '../budget_web_pdf/budget_web_pdf_view_model.dart';
import '../utils/web_pdf_saver.dart';

/// Tab "Meus dados" do orçamento Web — agora centraliza **tudo** o que o
/// cliente precisa ver num único scroll:
///
/// 1. Dados do cliente/orçamento (contato, informações, endereço) — read-only,
///    reutilizando as mesmas labels do app mobile.
/// 2. Lista de itens do orçamento (seção colapsável, com busca + **tabela**
///    com scroll horizontal).
/// 3. Lista de comentários/observações (seção colapsável, read-only).
///
/// No rodapé fixo (sempre visível durante o scroll) ficam, de cima para baixo:
/// - O botão **Aprovar/Reprovar** (bordas arredondadas, com padding),
///   refletindo o status atual (verde = aprovado, vermelho = reprovado) e
///   abrindo o modal de aprovação.
/// - A **barra de totais** (full-width, sem padding lateral) abaixo do botão.
///
/// O botão **Pré-visualizar PDF** (no conteúdo rolável) **abre o PDF em uma
/// nova aba** do navegador, usando o visualizador nativo cheio do browser
/// (scroll/zoom entre todas as páginas) — em vez da antiga tab de PDF com
/// o `<iframe>` embutido, que só mostrava a primeira página de forma
/// confiável. A geração dos bytes continua reutilizando o mesmo
/// `PdfGenerateUseCase` (via `BudgetWebPdfViewModel`): nenhuma regra de
/// negócio do PDF foi duplicada.
class BudgetWebDataView extends StatefulWidget {
  const BudgetWebDataView({
    super.key,
    required this.budget,
    required this.items,
    required this.observations,
    required this.owner,
    required this.token,
    required this.moneyConvert,
    required this.totalProducts,
    required this.totalServices,
    required this.totalBudget,
    required this.onApprove,
  });

  final CustomerInfo budget;
  final List<ItemsBudget> items;
  final List<ObservationPdf> observations;
  final OwnerPdf owner;
  final String token;
  final ConvertCoin moneyConvert;
  final double totalProducts;
  final double totalServices;
  final double totalBudget;

  /// Callback de aprovação/reprovação (gravado pelo ViewModel do orçamento).
  final ValueChanged<String> onApprove;

  @override
  State<BudgetWebDataView> createState() => _BudgetWebDataViewState();
}

class _BudgetWebDataViewState extends State<BudgetWebDataView> {
  final TextEditingController _searchController = TextEditingController();

  /// Gera os bytes do PDF sob demanda (mesma regra do app mobile) quando o
  /// cliente toca em "Pré-visualizar PDF". Reutiliza `BudgetWebPdfViewModel`
  /// — não duplica a geração do PDF.
  late final BudgetWebPdfViewModel _pdfViewModel;

  bool _generatingPdf = false;

  List<ItemsBudget> get _filteredItems {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((i) => (i.DESCRICAO ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _pdfViewModel = BudgetWebPdfViewModel(
      items: widget.items,
      customer: widget.budget,
      owner: widget.owner,
      observations: widget.observations,
      token: widget.token,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewModel.dispose();
    super.dispose();
  }

  Future<void> _openPdfInNewTab() async {
    // Já gerado antes? Abre direto.
    if (_pdfViewModel.bytes != null && !_pdfViewModel.loading) {
      openPdfInNewTabWeb(_pdfViewModel.bytes!);
      return;
    }
    setState(() => _generatingPdf = true);
    try {
      await _pdfViewModel.inicialData(context);
      final bytes = _pdfViewModel.bytes;
      if (bytes != null) {
        openPdfInNewTabWeb(bytes);
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // Layout em coluna: conteúdo rolável em cima, painel fixo (botão de
      // aprovar + totais) embaixo. O botão de aprovar fica **acima** da barra
      // de totais, com padding, seguindo a UX do projeto (botões arredondados).
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
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
                // Botão de pré-visualização do PDF: abre o orçamento no
                // visualizador nativo do navegador em uma **nova aba** (scroll
                // + zoom + download nativos, todas as páginas). Exclusivo da
                // versão Web. Reutiliza `BudgetWebPdfViewModel` para gerar os
                // bytes — mesma regra de negócio do PDF do app mobile.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
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
                      onPressed: _generatingPdf ? null : _openPdfInNewTab,
                      icon: _generatingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: buttonColor,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _generatingPdf
                            ? BudgetWebStrings.loading
                            : BudgetWebStrings.pdfPreviewButton,
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
          // Painel fixo do rodapé: botão de aprovar (com padding, arredondado,
          // acima do preço) + barra de totais (full-width, abaixo).
          Material(
            color: bgColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: BudgetWebApproveButton(
                    status: widget.budget.status,
                    onPressed: () async {
                      await showBudgetWebApprovalModal(
                        context,
                        onSelect: (status) => widget.onApprove(status),
                      );
                    },
                  ),
                ),
                BudgetWebItemsTotalBar(
                  moneyConvert: widget.moneyConvert,
                  totalProducts: widget.totalProducts,
                  totalServices: widget.totalServices,
                  totalBudget: widget.totalBudget,
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