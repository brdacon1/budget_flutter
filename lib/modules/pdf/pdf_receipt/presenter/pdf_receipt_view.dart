import 'dart:io';
import 'package:flutter/material.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'components/pdf_receipt_share_button.dart';
import 'pdf_receipt_view_model.dart';

class PdfReceiptView extends StatefulWidget {
  final Receipt receipt;
  final CustomerInfo item;
  const PdfReceiptView({super.key, required this.receipt, required this.item});

  @override
  State<PdfReceiptView> createState() => _PdfReceiptView();
}

class _PdfReceiptView extends State<PdfReceiptView> {
  late final PdfReceiptViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        PdfReceiptViewModel(receipt: widget.receipt, item: widget.item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData(context));
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
                        SfPdfViewer.file(
                          File(_viewModel.fileBytes!),
                        ),
                      if (_viewModel.fileBytes == null)
                        const Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                            strokeWidth: 1,
                          ),
                        ),
                      PdfReceiptShareButton(filePath: _viewModel.fileBytes),
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
