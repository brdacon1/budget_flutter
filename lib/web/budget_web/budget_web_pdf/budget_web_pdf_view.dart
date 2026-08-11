import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/web/strings/budget_web_strings.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../utils/web_pdf_saver.dart';
import 'budget_web_pdf_view_model.dart';

/// Tab "PDF" do orçamento Web.
///
/// Reutiliza a regra de negócio do PDF (`PdfGenerateUseCase`) e apresenta o
/// documento no navegador (`SfPdfViewer.memory`) com botão de download.
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
      ),
      body: Container(
        color: Colors.white,
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Stack(
              children: [
                if (_viewModel.bytes != null)
                  SfPdfViewer.memory(_viewModel.bytes!),
                if (_viewModel.loading)
                  const Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 1,
                    ),
                  ),
                if (_viewModel.bytes == null && !_viewModel.loading)
                  const Align(
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
                if (_viewModel.bytes != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: FadeAnimationWidget(
                        delay: 1,
                        child: TextButton(
                          onPressed: () => savePdfBytesWeb(
                            _viewModel.bytes!,
                            'orcamento.pdf',
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 60),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0)),
                          ),
                          child: Text(
                            BudgetWebStrings.pdfDownloadButton,
                            style: GoogleFonts.heebo(
                              color: bgColor,
                              letterSpacing: 0.5,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
