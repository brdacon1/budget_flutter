import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../Models/Db.dart';
import '../Models/PDFGenerate.dart';
import '../Services/display_alert.dart';
import '../anmition/fadeanimation.dart';
import 'package:share/share.dart';

import '../constants.dart';

class PdfViewPage extends StatefulWidget {
  const PdfViewPage({Key? key}) : super(key: key);
  @override
  _PdfViewPageState createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  String? _fileBytes;
  convert_coin moneyConvert = convert_coin();
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
        var db = Db();
        var pdf = PDFGenerate();
        var budget = await db.getListItensGerador();
        var customer = await db.getInformationOrcamento1();
        var owner = await db.getInformationEnterprise();
        var comment = await db.getListComentarioPDF();
        if (budget.isNotEmpty) {
          double totalProducts = 0;
          double totalServices = 0;
          double totalBudget = 0;
          int countProduct = 0;
          int countService = 0;

          for (int index = 0; index < budget.length; index++) {
            double total = budget[index].TOTAL!;
            if (budget[index].CATEGORIA == 'Produtos') {
              totalProducts += total;
              countProduct++;
            } else if (budget[index].CATEGORIA == 'Serviços') {
              totalServices += total;
              countService++;
            }
            totalBudget += total;
          }

          await pdf.patternPDF(countService, countProduct,
              moneyConvert.convertFromDouble(totalBudget),
              moneyConvert.convertFromDouble(totalProducts),
              moneyConvert.convertFromDouble(totalServices), budget, customer, owner, comment).then((value) {
                     setState(() {
                         _fileBytes = value;
                     });
          });
          setState(() {});
        } else {
          await displayAlert.notificationWarning(context, "Ops!", "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'");
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
                      child: FadeAnimation(
                        delay: 1,
                        child: TextButton(
                            onPressed: () async {
                              if(_fileBytes != null)
                                {
                                  Share.shareFiles([_fileBytes!], text: 'Compartilhar PDF');
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
