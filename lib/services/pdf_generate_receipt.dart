import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:oflite/models/payment_customer.dart';
import 'package:oflite/models/receipt.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as uid;
import 'package:oflite/models/global_uid_user.dart' as user_global;
import 'package:path_provider/path_provider.dart';
import 'http_request.dart';

class PdfGenerateReceipt {
  var db = HttpRequest();
  Future<String> patternPDF(
      List<PaymentCustomer> paymentList,
      Receipt recived,
      String totalPriceBudget,
      CustomerInfo obs2,
      OwnerPdf obs3) async {
    try
    {
      double count = 0;
      double resultTableProduct = 0;
      ConvertCoin moneyConvert = ConvertCoin();
      PdfDocument document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.left = 30;
      document.pageSettings.margins.right = 30;
      document.pageSettings.margins.top = 50;
      document.pageSettings.margins.bottom = 50;
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;
      double sizeWithImage = 0;
      String? token = '';
      ///Start image
      if (obs3.fotoId!.isNotEmpty) {
        try {

          if(uid.googleAuth!) {
            token = await db.authGoogle();
          }
          else{
            var auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: user_global.email!.trim(),
              password: user_global.password!.trim(),
            );
            token = await auth.user?.getIdToken();
          }

          var endpointUrl =
              'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${obs3.logoName}?alt=media&token=${obs3.fotoId}';
          var response = await http.get(
            Uri.parse(endpointUrl),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Accept': 'application/json;odata=verbose',
            },
          );

          if (response.statusCode == 200) {
            final Uint8List fileContent = response.bodyBytes;
            final PdfBitmap image = PdfBitmap(fileContent);

            final double originalRatio = image.width / image.height;
            final double sizeH = image.height.toDouble();
            final double sizeW = image.width.toDouble();
            Rect bounds;

            if (sizeH == sizeW) {
              sizeWithImage = 80 + 10;
              bounds = const Rect.fromLTWH(0, 0, 80, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            } else if (sizeH > sizeW) {
              sizeWithImage = 60 + 10;
              bounds = const Rect.fromLTWH(0, 0, 60, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            } else if (sizeH < sizeW) {
              sizeWithImage = (80 * originalRatio) + 10;
              bounds = Rect.fromLTWH(0, 0, 80 * originalRatio, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            }
          }
        } catch (e) {
          rethrow;
        }
      }
      ///End image

      PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.regular);

      PdfStringFormat format = PdfStringFormat(
        textDirection: PdfTextDirection.rightToLeft,
        alignment: PdfTextAlignment.right,
      );

      PdfGrid pdfGrid = PdfGrid();
      pdfGrid.columns.add(count: 2);
      PdfGridRow header = pdfGrid.headers.add(1)[0];
      header.cells[0].value = 'Informação';
      pdfGrid.headers.clear();
      PdfGridRow row;

      if (obs3.empresa?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.empresa;
      }

      if (obs3.cnpj?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.cnpj;
      }

      if (obs3.email?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.email;
      }

      if (obs3.fone?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.fone;
      }

      if (obs3.rua?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.rua!;
      }

      if (obs3.city?.isNotEmpty ?? false) {
        row = pdfGrid.rows.add();
        row.cells[0].value = obs3.city!;
      }

      PdfGridCellStyle style = PdfGridCellStyle();
      style.borders.all = PdfPens.transparent;

      for (int i = 0; i < pdfGrid.rows.count; i++) {
        PdfGridRow row = pdfGrid.rows[i];
        if(i == 0)
        {
          row.style.font = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);
        }
        else{
          row.style.font = PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.regular);
        }
        for (int j = 0; j < row.cells.count; j++) {
          PdfGridCell cell = row.cells[j];

          cell.style = style;
        }
      }

      PdfGridCellStyle headerStyle = PdfGridCellStyle(font: font, textBrush: PdfBrushes.black, textPen: PdfPens.white);
      pdfGrid.headers.applyStyle(headerStyle);
      pdfGrid.columns[0].width = 180;
      pdfGrid.columns[1].width = 620;
      pdfGrid.draw(graphics: page.graphics, bounds: Rect.fromLTWH(sizeWithImage, 0, page.getClientSize().width, page.getClientSize().height));

      format = PdfStringFormat(
        textDirection: PdfTextDirection.rightToLeft,
        alignment: PdfTextAlignment.center,
      );

      PdfFont font1 = PdfStandardFont(PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold);

      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Define o fundo branco
        pen: PdfPen(PdfColor(211, 211, 211)), // Define a cor cinza das bordas
        bounds: Rect.fromLTWH(0, 95, page.getClientSize().width, 30),
      );

      graphics.drawString(
        '\nDADOS DO RECIBO',
        font1,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(0, 86.5, page.getClientSize().width, page.getClientSize().height),
        format: format,
      );

      try {

        PdfGrid pdfGrid = PdfGrid();
        pdfGrid.columns.add(count: 2);
        PdfGridRow header = pdfGrid.headers.add(1)[0];
        header.cells[0].value = 'Informação';
        header.cells[1].value = 'Dados';
        pdfGrid.headers.clear();

        PdfGridRow row;

        if (obs2.id?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Número do orçamento:';
          row.cells[1].value = obs2.id!;
        }

        if (obs2.customerName?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Cliente :';
          row.cells[1].value = obs2.customerName!;
        }

        if (obs2.phone?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Telefone :';
          row.cells[1].value = obs2.phone!;
          count += 10;
        }

        PdfGridCellStyle style = PdfGridCellStyle();
        style.borders.all = PdfPens.transparent;

        for (int i = 0; i < pdfGrid.rows.count; i++) {
          PdfGridRow row = pdfGrid.rows[i];
          for (int j = 0; j < row.cells.count; j++) {
            PdfGridCell cell = row.cells[j];
            cell.style = style;
          }
        }

        PdfGridCellStyle headerStyle = PdfGridCellStyle(font: font, textBrush: PdfBrushes.black, textPen: PdfPens.white);
        pdfGrid.headers.applyStyle(headerStyle);
        pdfGrid.columns[0].width = 110;
        pdfGrid.columns[1].width = 360;
        pdfGrid.draw(graphics: page.graphics, bounds: Rect.fromLTWH(page.getClientSize().width / 2, 135, page.getClientSize().width, page.getClientSize().height));

      }
      catch (e)
      {
        rethrow;
      }

      ///Recibo info
      try {

        PdfGrid pdfGrid = PdfGrid();
        pdfGrid.columns.add(count: 2);
        PdfGridRow header = pdfGrid.headers.add(1)[0];
        header.cells[0].value = 'Informação';
        header.cells[1].value = 'Dados';
        pdfGrid.headers.clear();

        PdfGridRow row;

        if (recived.ID?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Número do recibo:';
          row.cells[1].value = recived.ID!;
        }

        if (recived.DATA?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Data do recibo :';
          row.cells[1].value = recived.DATA!;
        }

        if (recived.DESCRICAO?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Nome do recibo :';
          row.cells[1].value = recived.DESCRICAO!;
        }

        PdfGridCellStyle style = PdfGridCellStyle();
        style.borders.all = PdfPens.transparent;

        for (int i = 0; i < pdfGrid.rows.count; i++) {
          PdfGridRow row = pdfGrid.rows[i];
          for (int j = 0; j < row.cells.count; j++) {
            PdfGridCell cell = row.cells[j];
            cell.style = style;
          }
        }

        PdfGridCellStyle headerStyle = PdfGridCellStyle(font: font, textBrush: PdfBrushes.black, textPen: PdfPens.white);
        pdfGrid.headers.applyStyle(headerStyle);
        pdfGrid.columns[0].width = 70;
        pdfGrid.columns[1].width = 360;
        pdfGrid.draw(graphics: page.graphics, bounds: Rect.fromLTWH(0, 135, page.getClientSize().width, page.getClientSize().height));

      }
      catch (e)
      {
        rethrow;
      }
      ///end recibo

      graphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Define o fundo branco
        pen: PdfPen(PdfColor(211, 211, 211)), // Define a cor cinza das bordas
        bounds: Rect.fromLTWH(0, 180 + count, page.getClientSize().width, 30),
      );

      graphics.drawString(
          'PAGAMENTOS REALIZADOS',
          font1,
          brush: PdfBrushes.black,
          bounds: Rect.fromLTWH(0, 187 + count, page.getClientSize().width, page.getClientSize().height),
          format: format
      );

      ///Start table service
      if(paymentList.isNotEmpty)
      {
        PdfGrid gridService = PdfGrid();
        PdfGridRow rowService;

        gridService.columns.add(count: 5);
        PdfGridRow headerService = gridService.headers.add(1)[0];
        headerService.cells[0].value = 'Descrição dos pagamentos';
        headerService.cells[1].value = 'Metodo de pagamento';
        headerService.cells[2].value = 'Valor pago';

        PdfFont fontHeaderService = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
        PdfGridCellStyle headerStyleService = PdfGridCellStyle(font: fontHeaderService,
            backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
            textBrush: PdfBrushes.black,
            cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5));
        headerStyleService.borders.left = PdfPens.transparent;
        headerStyleService.borders.right = PdfPens.transparent;
        headerStyleService.borders.top = PdfPens.lightGray;
        headerStyleService.borders.bottom = PdfPens.lightGray;
        headerService.height = 25;
        gridService.headers.applyStyle(headerStyleService);
        gridService.columns[0].width = 200;
        gridService.columns[1].width = 180;
        gridService.columns[2].width = 105;

        for (int index = 0; index < paymentList.length; index++)
        {
          rowService = gridService.rows.add();
          rowService.cells[0].value = paymentList[index].DESCRICAO!;
          rowService.cells[1].value = paymentList[index].METODO!;
          rowService.cells[2].value = moneyConvert.convertFromDouble(paymentList[index].PRECO!);
        }

        PdfGridCellStyle styleRowService = PdfGridCellStyle();
        styleRowService.cellPadding = PdfPaddings(top: 5, left: 5, right: 5, bottom: 5);
        styleRowService.borders.left = PdfPens.transparent;
        styleRowService.borders.right = PdfPens.transparent;
        styleRowService.borders.top = PdfPens.lightGray;
        styleRowService.borders.bottom = PdfPens.lightGray;

        for (int i = 0; i < gridService.rows.count; i++) {
          rowService = gridService.rows[i];
          for (int j = 0; j < rowService.cells.count; j++) {
            PdfGridCell cell = rowService.cells[j];
            cell.style = styleRowService;
          }
        }

        PdfGridRow totalRowBudget = gridService.rows.add();
        totalRowBudget.cells[1].value = 'Valor total pago:';
        totalRowBudget.cells[2].value = totalPriceBudget;
        PdfGridCellStyle totalRowStyleBudget = PdfGridCellStyle(
          font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          textBrush: PdfBrushes.black,
          cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
          backgroundBrush: PdfSolidBrush(PdfColor(245,245,245)),
        );

        totalRowStyleBudget.borders.left = PdfPens.transparent;
        totalRowStyleBudget.borders.right = PdfPens.transparent;
        totalRowStyleBudget.borders.top = PdfPens.lightGray;
        totalRowStyleBudget.borders.bottom = PdfPens.transparent;
        totalRowBudget.cells[0].style = totalRowStyleBudget;
        totalRowBudget.cells[1].style = totalRowStyleBudget;
        totalRowBudget.cells[2].style = totalRowStyleBudget;
        totalRowBudget.cells[3].style = totalRowStyleBudget;
        totalRowBudget.cells[4].style = totalRowStyleBudget;
        totalRowBudget.height = 30;
        totalRowBudget.style = totalRowStyleBudget;
        ///end Total Budget

        PdfLayoutFormat layoutFormatService = PdfLayoutFormat(
          breakType: PdfLayoutBreakType.fitPage,
          layoutType: PdfLayoutType.paginate,
        );

        gridService.draw(
          page: page,
          format: layoutFormatService,
          bounds: Rect.fromLTWH(0, 220 + count +  resultTableProduct, page.getClientSize().width, page.getClientSize().height),
        );
      }
      ///end table service

      final directory = await getApplicationSupportDirectory();
      final path = directory.path;
      File file = File('$path/${budget.IDORCAMENTO}.pdf');
      await file.writeAsBytes(await document.save(), flush: true);
      String localFile = '$path/${budget.IDORCAMENTO}.pdf';
      document.dispose();
      return localFile;
    }
    catch (e)
    {
      rethrow;
    }
  }
}
