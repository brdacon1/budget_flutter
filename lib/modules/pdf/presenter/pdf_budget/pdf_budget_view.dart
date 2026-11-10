import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/pdf/domain/entity/pdf_layout_type.dart';
import 'package:oflite/modules/pdf/presenter/pdf_budget/pdf_budget_view_model.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfBudgetView extends StatefulWidget {
  final PdfLayoutType layoutType;

  const PdfBudgetView({super.key, this.layoutType = PdfLayoutType.standard});

  @override
  State<PdfBudgetView> createState() => _PdfBudgetView();
}

class _PdfBudgetView extends State<PdfBudgetView> {
  late final PdfBudgetViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<PdfBudgetViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.setLayoutType(widget.layoutType);
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
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
                              onPressed: () async {
                                if (_viewModel.fileBytes != null) {
                                  final xFile = XFile(_viewModel.fileBytes!);
                                  await SharePlus.instance.share(
                                    ShareParams(
                                      files: [xFile],
                                      text: PdfStrings.sharePdf,
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15.0,
                                  horizontal: 80,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
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
