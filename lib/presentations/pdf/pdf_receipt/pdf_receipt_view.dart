import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/Services/pdf_generate_receipt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../models/customer_info.dart';
import '../../../models/receipt.dart';
import '../../../Services/display_alert.dart';
import 'package:share_plus/share_plus.dart';
import '../../../common/constants/constants.dart';

class PdfReceiptView extends StatefulWidget {
  final Receipt receipt;
  final CustomerInfo item;
  const PdfReceiptView({Key? key, required this.receipt, required this.item}) : super(key: key);

  @override
  State<PdfReceiptView> createState() => _PdfReceiptView();
}

class _PdfReceiptView extends State<PdfReceiptView> {
  String? _fileBytes;
  ConvertCoin moneyConvert = ConvertCoin();
  var displayAlert = DisplayAlert();

  @override
  void initState() {
    super.initState();
    startPDF();
  }

  Future<void> startPDF() async {
    try {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        var db = HttpRequest();
        var pdf = PdfGenerateReceipt();
        var recived = await db.getListRecived();
        var payment = await db.getListPayment(widget.receipt, widget.item);
        var owner = await db.getInformationEnterprise();
        if (recived.isNotEmpty) {
          double totalBudget = 0;

          for (int index = 0; index < payment.length; index++) {
            double total = payment[index].PRECO!;
            totalBudget += total;
          }

          await pdf.patternPDF(
              payment,
              widget.receipt,
              moneyConvert.convertFromDouble(totalBudget),
              widget.item,
              owner).then((value) {
                   setState(() {
                     _fileBytes = value;
                   });
          });

          setState(() {});
        } else {
          await displayAlert.notificationError(context, "Erro!", "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'");
        }
      }
    } catch (ex) {}
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
              child: Stack(
                children: [
                  if (_fileBytes != null)
                    SfPdfViewer.file(
                      File(_fileBytes!),
                    ),
                  if (_fileBytes == null)
                    const Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
                              if(_fileBytes != null)
                              {
                                final xFile = XFile(_fileBytes!);
                                Share.shareXFiles([xFile], text: 'Compartilhar PDF');
                              }
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 80),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)
                                )
                            ),
                            child: Text("COMPARTILHAR", style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                            )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
