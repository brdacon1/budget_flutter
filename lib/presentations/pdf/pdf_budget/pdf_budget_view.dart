import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../common/widgets/anmition/fade_animation_widget.dart';
import '../../../common/constants/constants.dart';
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
    _viewModel = PdfBudgetViewModel();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _viewModel.initialData(context));
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
        title: const Text('PDF'),
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
                                  Share.shareXFiles([xFile],
                                      text: 'Compartilhar PDF');
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
                                'COMPARTILHAR',
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
