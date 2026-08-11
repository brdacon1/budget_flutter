import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import '../utils/web_pdf_saver.dart';
import 'budget_web_pdf_view_model.dart';
import 'web_pdf_viewer.dart';

/// Tab "PDF" do orçamento Web.
///
/// Reutiliza a regra de negócio do PDF (`PdfGenerateUseCase`) e apresenta o
/// documento no navegador via `WebPdfViewer` (no Web, um `<iframe>` com o
/// visualizador nativo do navegador — scroll/zoom/download nativos) com
/// botão de download explícito.
class BudgetWebPdfView extends StatefulWidget {
  const BudgetWebPdfView({
    super.key,
    required this.items,
    required this.customer,
    required this.owner,
    required this.observations,
    required this.token,
  });

  final dynamic items;
  final dynamic customer;
  final dynamic owner;
  final dynamic observations;
  final String token;

  @override
  State<BudgetWebPdfView> createState() => _BudgetWebPdfViewState();
}

class _BudgetWebPdfViewState extends State<BudgetWebPdfView> {
  late final BudgetWebPdfViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetWebPdfViewModel(
      items: widget.items,
      customer: widget.customer,
      owner: widget.owner,
      observations: widget.observations,
      token: widget.token,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.inicialData(context);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(BudgetWebStrings.pdfTitle),
        backgroundColor: bgColor,
        foregroundColor: whiteColor,
        // Botão de download no AppBar (e não sobre o iframe). No Flutter Web,
        // o `WebPdfViewer` é um `<iframe>` (HtmlElementView/platform view)
        // renderizado como elemento HTML por cima do canvas do Flutter, que
        // intercepta os toques na sua área. Um botão `Positioned` por cima do
        // iframe ficava visível mas encoberto — o clique caía no visualizador
        // de PDF do navegador (o tal "zoom absurdo") em vez de baixar. No
        // AppBar, fora da área do iframe, o botão é clicável de verdade.
        actions: [
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final ready =
                  _viewModel.bytes != null && !_viewModel.loading;
              // "Abrir em nova aba": usa o visualizador nativo cheio do
              // navegador. No mobile é o jeito confiável de ver/todas as
              // páginas do orçamento (scroll + zoom nativos), já que o
              // <iframe> embutido costuma ser limitado em telas estreitas.
              return IconButton(
                tooltip: BudgetWebStrings.pdfOpenNewTab,
                onPressed: ready
                    ? () => openPdfInNewTabWeb(_viewModel.bytes!)
                    : null,
                icon: const Icon(Icons.open_in_new),
                color: whiteColor,
              );
            },
          ),
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              final ready =
                  _viewModel.bytes != null && !_viewModel.loading;
              return TextButton.icon(
                onPressed: ready
                    ? () => savePdfBytesWeb(
                          _viewModel.bytes!,
                          'orcamento.pdf',
                        )
                    : null,
                icon: const Icon(Icons.download_outlined),
                label: Text(
                  BudgetWebStrings.pdfDownloadButton,
                  style: GoogleFonts.heebo(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            // O `WebPdfViewer` (iframe no Web) precisa de restrições
            // "tight" para preencher a área — por isso fica com
            // `Positioned.fill`. Os estados de loading/empty também.
            return Stack(
              children: [
                if (_viewModel.bytes != null)
                  Positioned.fill(
                    child: WebPdfViewer(bytes: _viewModel.bytes!),
                  ),
                if (_viewModel.loading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                if (_viewModel.bytes == null && !_viewModel.loading)
                  const Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nenhum PDF disponível para este orçamento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
