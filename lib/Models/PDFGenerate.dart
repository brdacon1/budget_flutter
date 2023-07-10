import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../Objetos/DADOS.dart';
import '../Objetos/ItensListBudget.dart';
import '../Objetos/ObjectListObservationPDF.dart';
import '../Objetos/Owner.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as budget;
import 'package:path_provider/path_provider.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as globalUIDUser;

class PDFGenerate {
  Future<String> patternPDF(
      int countService,
      int countProduct,
      String totalPriceBudget,
      String totalPriceProducts,
      String totalPriceServices,
      List<ItensListBudget> obs1,
      DADOS obs2,
      Owner obs3,
      List<ObjectListObservationPDF> obs4) async {
    try
    {
      double count = 0;
      double resultTableProduct = 0;
      convert_coin moneyConvert = convert_coin();
      PdfDocument document = PdfDocument();
      document.pageSettings.size = PdfPageSize.a4;
      document.pageSettings.margins.left = 30;
      document.pageSettings.margins.right = 30;
      document.pageSettings.margins.top = 50;
      document.pageSettings.margins.bottom = 50;
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;

      ///Start image
      if (obs3.fotoId!.isNotEmpty) {
        try {
          var auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: globalUIDUser.EMAIL!.trim(),
            password: globalUIDUser.Senha!.trim(),
          );
          var token = await auth.user?.getIdToken();
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
              bounds = const Rect.fromLTWH(0, 0, 80, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            } else if (sizeH > sizeW) {
              bounds = const Rect.fromLTWH(0, 0, 60, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            } else if (sizeH < sizeW) {
              bounds = Rect.fromLTWH(0, 0, 80 * originalRatio, 80);
              page.graphics.drawImage(image, Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height));
            }
          }
        } catch (e) {
          rethrow;
        }
      }
      ///End image

      PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

      PdfStringFormat format = PdfStringFormat(
        textDirection: PdfTextDirection.rightToLeft,
        alignment: PdfTextAlignment.right,
      );

      font = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.regular);

      graphics.drawString(
        '${obs3.empresa}\n${obs3.rua}\n${obs3.city}  ${obs3.bairro}\nCEP: ${obs3.cep}\nE-mail: ${obs3.email}\nTelefone: ${obs3.fone}',
        font,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, page.getClientSize().height),
        format: format,
      );

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
        '\nDADOS DO ORÇAMENTO',
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

        if (obs2?.ID?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Número :';
          row.cells[1].value = obs2.ID!;
        }

        if (obs2?.DATA?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Criado em :';
          row.cells[1].value = obs2.DATA!;
        }

        if (obs2?.NOMECLIENTE?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Cliente :';
          row.cells[1].value = obs2.NOMECLIENTE!;
        }

        if (obs2?.FONE?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Telefone :';
          row.cells[1].value = obs2.FONE!;
          count += 15;
        }

        if (obs2?.NOMEEMPRESA?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Empresa :';
          row.cells[1].value = obs2.NOMEEMPRESA!;
          count += 10;
        }

        if (obs2?.RUA?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Rua :';
          row.cells[1].value = obs2.RUA!;
          count += 10;
        }

        if (obs2?.BAIRRO?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Bairro :';
          row.cells[1].value = obs2.BAIRRO!;
          count += 10;
        }

        if (obs2?.CITY?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'Cidade :';
          row.cells[1].value = obs2.CITY!;
          count += 10;
        }

        if (obs2?.CEP?.isNotEmpty ?? false) {
          row = pdfGrid.rows.add();
          row.cells[0].value = 'CEP :';
          row.cells[1].value = obs2.CEP!;
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
        pdfGrid.columns[0].width = 70;
        pdfGrid.columns[1].width = 360;
        pdfGrid.draw(graphics: page.graphics, bounds: Rect.fromLTWH(0, 135, page.getClientSize().width, page.getClientSize().height));

      }
      catch (e)
      {
        rethrow;
      }

      graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Define o fundo branco
          pen: PdfPen(PdfColor(211, 211, 211)), // Define a cor cinza das bordas
          bounds: Rect.fromLTWH(0, 200 + count, page.getClientSize().width, 30),
      );

      graphics.drawString(
          'LISTA DE ITENS DO ORÇAMENTO',
          font1,
          brush: PdfBrushes.black,
          bounds: Rect.fromLTWH(0, 207 + count, page.getClientSize().width, page.getClientSize().height),
          format: format
      );

      ///Start table product
      if(countProduct > 0)
      {
        PdfGrid grid = PdfGrid();
        PdfGridRow totalRowProduct;
        grid.columns.add(count: 5);
        PdfGridRow header = grid.headers.add(1)[0];
        header.cells[0].value = 'Descrição dos produtos';
        header.cells[1].value = 'Medida';
        header.cells[2].value = 'Qtd';
        header.cells[3].value = 'Preço';
        header.cells[4].value = 'Total';

        PdfFont fontHeader = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
        PdfGridCellStyle headerStyle = PdfGridCellStyle(font: fontHeader,
            backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
            textBrush: PdfBrushes.black,
            cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5));
        headerStyle.borders.left = PdfPens.transparent;
        headerStyle.borders.right = PdfPens.transparent;
        headerStyle.borders.top = PdfPens.lightGray;
        headerStyle.borders.bottom = PdfPens.lightGray;
        header.height = 25;
        grid.headers.applyStyle(headerStyle);
        grid.columns[0].width = 200;
        grid.columns[1].width = 75;
        grid.columns[3].width = 105;
        grid.columns[4].width = 105;

        for (int index = 0; index < obs1.length; index++)
        {
          if(obs1[index].CATEGORIA == 'Produtos')
          {
            totalRowProduct = grid.rows.add();
            totalRowProduct.cells[0].value = obs1[index].DESCRICAO!;
            totalRowProduct.cells[1].value = obs1[index].MEDIDA!;
            totalRowProduct.cells[2].value = obs1[index].QTD.toString();
            totalRowProduct.cells[3].value = moneyConvert.convertFromDouble(obs1[index].PRECO!);
            totalRowProduct.cells[4].value = moneyConvert.convertFromDouble(obs1[index].TOTAL!);
          }
        }

        PdfGridCellStyle styleProductTable = PdfGridCellStyle();
        styleProductTable.cellPadding = PdfPaddings(top: 5, left: 5, right: 5, bottom: 5);
        styleProductTable.borders.left = PdfPens.transparent;
        styleProductTable.borders.right = PdfPens.transparent;
        styleProductTable.borders.top = PdfPens.lightGray;
        styleProductTable.borders.bottom = PdfPens.lightGray;

        for (int i = 0; i < grid.rows.count; i++) {
          totalRowProduct = grid.rows[i];
          for (int j = 0; j < totalRowProduct.cells.count; j++) {
            PdfGridCell cell = totalRowProduct.cells[j];
            cell.style = styleProductTable;
          }
        }

        totalRowProduct = grid.rows.add();
        totalRowProduct.cells[3].value = 'Valor de produtos:';
        totalRowProduct.cells[4].value = totalPriceProducts;
        PdfGridCellStyle totalRowStyleProduct = PdfGridCellStyle(
          font: fontHeader,
          cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
          textBrush: PdfBrushes.black,
          backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
        );
        totalRowStyleProduct.borders.left = PdfPens.transparent;
        totalRowStyleProduct.borders.right = PdfPens.transparent;
        totalRowStyleProduct.borders.top = PdfPens.lightGray;
        totalRowStyleProduct.borders.bottom = PdfPens.lightGray;
        totalRowProduct.cells[0].style = totalRowStyleProduct;
        totalRowProduct.cells[1].style = totalRowStyleProduct;
        totalRowProduct.cells[2].style = totalRowStyleProduct;
        totalRowProduct.cells[3].style = totalRowStyleProduct;
        totalRowProduct.cells[4].style = totalRowStyleProduct;
        totalRowProduct.height = 25;
        totalRowProduct.style = totalRowStyleProduct;

        ///Start Valor total
        if(countService <= 0)
        {
          PdfGridRow totalRowBudget = grid.rows.add();
          totalRowBudget.cells[3].value = 'Valor total:';
          totalRowBudget.cells[4].value = totalPriceBudget;
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
        }
        ///end Total Budget


        PdfLayoutFormat layoutFormatProduct = PdfLayoutFormat(
          breakType: PdfLayoutBreakType.fitPage,
          layoutType: PdfLayoutType.paginate,
        );

        PdfLayoutResult result = grid.draw(
          page: page,
          format: layoutFormatProduct,
          bounds: Rect.fromLTWH(0, 240 + count, page.getClientSize().width, page.getClientSize().height),
        ) as PdfLayoutResult;
        resultTableProduct = result.bounds.height;
      }
      ///End table product

      ///Start table service
      if(countService > 0)
      {
        PdfGrid gridService = PdfGrid();
        PdfGridRow rowService;

        gridService.columns.add(count: 5);
        PdfGridRow headerService = gridService.headers.add(1)[0];
        headerService.cells[0].value = 'Descrição dos serviços';
        headerService.cells[1].value = 'Medida';
        headerService.cells[2].value = 'Qtd';
        headerService.cells[3].value = 'Preço';
        headerService.cells[4].value = 'Total';

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
        gridService.columns[1].width = 75;
        gridService.columns[3].width = 105;
        gridService.columns[4].width = 105;

        for (int index = 0; index < obs1.length; index++)
        {
          if(obs1[index].CATEGORIA == 'Serviços')
          {
            rowService = gridService.rows.add();
            rowService.cells[0].value = obs1[index].DESCRICAO!;
            rowService.cells[1].value = obs1[index].MEDIDA!;
            rowService.cells[2].value = obs1[index].QTD.toString();
            rowService.cells[3].value = moneyConvert.convertFromDouble(obs1[index].PRECO!);
            rowService.cells[4].value = moneyConvert.convertFromDouble(obs1[index].TOTAL!);
          }
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

        PdfGridRow totalRowService = gridService.rows.add();
        totalRowService.cells[3].value = 'Valor de serviços:';
        totalRowService.cells[4].value = totalPriceServices;
        PdfGridCellStyle totalRowStyleService = PdfGridCellStyle(
          font: fontHeaderService,
          textBrush: PdfBrushes.black,
          cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
          backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
        );

        totalRowStyleService.borders.left = PdfPens.transparent;
        totalRowStyleService.borders.right = PdfPens.transparent;
        totalRowStyleService.borders.top = PdfPens.lightGray;
        totalRowStyleService.borders.bottom = PdfPens.lightGray;
        totalRowService.cells[0].style = totalRowStyleService;
        totalRowService.cells[1].style = totalRowStyleService;
        totalRowService.cells[2].style = totalRowStyleService;
        totalRowService.cells[3].style = totalRowStyleService;
        totalRowService.cells[4].style = totalRowStyleService;
        totalRowService.height = 25;
        totalRowService.style = totalRowStyleService;

        PdfGridRow totalRowBudget = gridService.rows.add();
        totalRowBudget.cells[3].value = 'Valor total:';
        totalRowBudget.cells[4].value = totalPriceBudget;
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
          bounds: Rect.fromLTWH(0, 240 + count +  resultTableProduct, page.getClientSize().width, page.getClientSize().height),
        );
      }
      ///end table service

      ///Start table comment
      if (obs4.isNotEmpty)
      {
         PdfPage pageComment = document.pages.add();
         PdfGraphics graphicsComment = pageComment.graphics;
         graphicsComment.drawRectangle(
           brush: PdfSolidBrush(PdfColor(255, 255, 255)), // Define o fundo branco
           pen: PdfPen(PdfColor(211, 211, 211)), // Define a cor cinza das bordas
           bounds: Rect.fromLTWH(0, 0, pageComment.getClientSize().width, 30),
         );

         graphicsComment.drawString(
           'OBSERVAÇÕES DO ORÇAMENTO',
           font1,
           brush: PdfBrushes.black,
           bounds: Rect.fromLTWH(0, 8.5, pageComment.getClientSize().width, pageComment.getClientSize().height),
           format: format,
         );

         PdfGrid commentPdfGrid = PdfGrid();
         commentPdfGrid.columns.add(count: 5);
         PdfGridRow headerComment = commentPdfGrid.headers.add(1)[0];
         headerComment.cells[0].value = 'Data';
         headerComment.cells[1].value = 'Observação';

         PdfStringFormat formatComment = PdfStringFormat(
           textDirection: PdfTextDirection.leftToRight,
           alignment: PdfTextAlignment.center,
         );

         PdfFont fontHeaderComment = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

         PdfGridCellStyle headerStyleComment = PdfGridCellStyle(font: fontHeaderComment,
         format: formatComment,
         backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
         textBrush: PdfBrushes.black);
         headerStyleComment.borders.left = PdfPens.transparent;
         headerStyleComment.borders.right = PdfPens.transparent;
         headerStyleComment.borders.top = PdfPens.lightGray;
         headerStyleComment.borders.bottom = PdfPens.lightGray;
         commentPdfGrid.headers.applyStyle(headerStyleComment);
         commentPdfGrid.columns[0].width = 75;
         commentPdfGrid.columns[1].width = 460;
         PdfLayoutFormat layoutFormatComment = PdfLayoutFormat();
         layoutFormatComment.breakType = PdfLayoutBreakType.fitPage;
         layoutFormatComment.layoutType = PdfLayoutType.paginate;

         PdfGridRow rowComment;

         for (int index = 0; index < obs4.length; index++)
         {
             rowComment = commentPdfGrid.rows.add();
             rowComment.cells[0].value = obs4[index].data!;
             rowComment.cells[1].value = obs4[index].observacao!;
         }

         PdfGridCellStyle styleComment = PdfGridCellStyle();
         styleComment.cellPadding = PdfPaddings(top: 5, left: 15, right: 5, bottom: 5);
         styleComment.borders.left = PdfPens.transparent;
         styleComment.borders.right = PdfPens.transparent;
         styleComment.borders.top = PdfPens.lightGray;
         styleComment.borders.bottom = PdfPens.lightGray;

         for (int i = 0; i < commentPdfGrid.rows.count; i++) {
           rowComment = commentPdfGrid.rows[i];
           for (int j = 0; j < rowComment.cells.count; j++) {
             PdfGridCell cell = rowComment.cells[j];
             cell.style = styleComment;
           }
         }

         commentPdfGrid.draw(
            page: pageComment,
            bounds: Rect.fromLTWH(0, 50, pageComment.getClientSize().width, pageComment.getClientSize().height),
            format: layoutFormatComment,
         );
      }
      ///End table comment

      final directory = await getApplicationSupportDirectory();
      final path = directory.path;
      File file = File('$path/${budget.IDORCAMENTO}.pdf');
      await file.writeAsBytes(await document.save(), flush: true);
      String localFile = '$path/${budget.IDORCAMENTO}.pdf';

      obs1.clear();
      obs4.clear();
      document.dispose();
      return localFile;
    }
    catch (e)
    {
      rethrow;
    }
  }
}
