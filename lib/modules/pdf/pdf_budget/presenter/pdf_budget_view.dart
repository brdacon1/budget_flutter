import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'pdf_budget_view_model.dart';

class PdfBudgetView extends StatefulWidget {
  const PdfBudgetView({super.key});

  @override
  State<PdfBudgetView> createState() => _PdfBudgetView();
}

class _PdfBudgetView extends State<PdfBudgetView> {
  late final PdfBudgetViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<PdfBudgetViewModel>();
    // Dispara o carregamento no próximo frame. Poderia rodar depois de
    // `dispose` se a tela fosse fechada muito rápido — o VM agora ignora
    // notificações pós-dispose, mas mesmo assim só disparamos se a View
    // ainda estiver montada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.initialData(context);
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
        title: Text(PdfStrings.pdfTitle),
        backgroundColor: bgColor,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, _) {
                  return Stack(
                    children: [
                      if (_viewModel.fileBytes != null)
                        SfPdfViewer.file(File(_viewModel.fileBytes!)),
                      if (_viewModel.loading)
                        const Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 1,
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: FadeAnimationWidget(
                            delay: 1,
                            child: TextButton(
                              onPressed: () {
                                if (_viewModel.fileBytes != null) {
                                  final xFile = XFile(_viewModel.fileBytes!);
                                  Share.shareXFiles([xFile], text: PdfStrings.sharePdf);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 80),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30.0)),
                              ),
                              child: Text(
                                PdfStrings.shareButton,
                                style: GoogleFonts.heebo(
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                  fontSize: 20.0,
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
          ],
        ),
      ),
    );
  }
}
