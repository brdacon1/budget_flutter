import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/global_uid_user.dart' as uid;
import 'package:oflite/shared/models/global_uid_user.dart' as user_global;
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/modules/core/services/data/service/convert_coin.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do recibo (dados do titular, dados do orçamento,
/// dados do recibo e tabela de pagamentos realizados).
class PdfGenerateReceiptUseCase {
  final HttpRequest _db = HttpRequest();
  final ConvertCoin _moneyConvert = ConvertCoin();

  Future<String> patternPDF({
    required List<PaymentCustomer> paymentList,
    required Receipt recived,
    required String totalPriceBudget,
    required CustomerInfo customer,
    required OwnerPdf owner,
  }) async {
    try {
      final PdfDocument document = _createDocument();
      final PdfPage page = document.pages.add();
      final PdfGraphics graphics = page.graphics;

      final double sizeWithImage = await _drawLogo(page, owner);

      _drawOwnerGrid(page, owner, sizeWithImage);
      _drawReceiptTitle(page, graphics);
      final double count = _drawBudgetDataGrid(page, customer);
      _drawReceiptInfoGrid(page, recived);

      _drawPaymentsSectionTitle(page, graphics, count);

      if (paymentList.isNotEmpty) {
        _drawPaymentsTable(
          page: page,
          count: count,
          paymentList: paymentList,
          totalPriceBudget: totalPriceBudget,
        );
      }

      final String localFile = await _saveDocument(document);
      document.dispose();
      return localFile;
    } catch (_) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Document setup
  // ---------------------------------------------------------------------------

  PdfDocument _createDocument() {
    final PdfDocument document = PdfDocument()
      ..pageSettings.size = PdfPageSize.a4
      ..pageSettings.margins.left = 30
      ..pageSettings.margins.right = 30
      ..pageSettings.margins.top = 50
      ..pageSettings.margins.bottom = 50;
    return document;
  }

  // ---------------------------------------------------------------------------
  // Logo / image
  // ---------------------------------------------------------------------------

  Future<double> _drawLogo(PdfPage page, OwnerPdf owner) async {
    if (owner.fotoId == null || owner.fotoId!.isEmpty) {
      return 0;
    }

    try {
      final String token = await _getAuthToken();

      final String endpointUrl =
          'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=${owner.fotoId}';
      final http.Response response = await http.get(
        Uri.parse(endpointUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json;odata=verbose',
        },
      );

      if (response.statusCode != 200) {
        return 0;
      }

      final Uint8List fileContent = response.bodyBytes;
      final PdfBitmap image = PdfBitmap(fileContent);

      final double originalRatio = image.width / image.height;
      final double sizeH = image.height.toDouble();
      final double sizeW = image.width.toDouble();

      Rect bounds;
      double sizeWithImage;

      if (sizeH == sizeW) {
        sizeWithImage = 80 + 10;
        bounds = const Rect.fromLTWH(0, 0, 80, 80);
      } else if (sizeH > sizeW) {
        sizeWithImage = 60 + 10;
        bounds = const Rect.fromLTWH(0, 0, 60, 80);
      } else {
        sizeWithImage = (80 * originalRatio) + 10;
        bounds = Rect.fromLTWH(0, 0, 80 * originalRatio, 80);
      }

      page.graphics.drawImage(
        image,
        Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height),
      );
      return sizeWithImage;
    } catch (_) {
      rethrow;
    }
  }

  Future<String> _getAuthToken() async {
    if (uid.googleAuth!) {
      return _db.authGoogle();
    }
    final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: user_global.email!.trim(),
      password: user_global.password!.trim(),
    );
    return (await auth.user?.getIdToken()) ?? '';
  }

  // ---------------------------------------------------------------------------
  // Owner info grid
  // ---------------------------------------------------------------------------

  void _drawOwnerGrid(PdfPage page, OwnerPdf owner, double sizeWithImage) {
    final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
    pdfGrid.headers.clear();

    void addRow(String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = pdfGrid.rows.add();
      row.cells[0].value = value;
    }

    addRow(owner.empresa);
    addRow(owner.cnpj);
    addRow(owner.email);
    addRow(owner.fone);
    addRow(owner.rua);
    addRow(owner.city);

    final PdfGridCellStyle style = PdfGridCellStyle()
      ..borders.all = PdfPens.transparent;

    for (int i = 0; i < pdfGrid.rows.count; i++) {
      final PdfGridRow row = pdfGrid.rows[i];
      row.style.font = i == 0
          ? PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold)
          : PdfStandardFont(
              PdfFontFamily.helvetica,
              8,
              style: PdfFontStyle.regular,
            );
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style = style;
      }
    }

    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.regular,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: font,
      textBrush: PdfBrushes.black,
      textPen: PdfPens.white,
    );
    pdfGrid.headers.applyStyle(headerStyle);
    pdfGrid.columns[0].width = 180;
    pdfGrid.columns[1].width = 620;
    pdfGrid.draw(
      graphics: page.graphics,
      bounds: Rect.fromLTWH(
        sizeWithImage,
        0,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Receipt section title
  // ---------------------------------------------------------------------------

  void _drawReceiptTitle(PdfPage page, PdfGraphics graphics) {
    final PdfFont font1 = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final PdfStringFormat format = PdfStringFormat(
      textDirection: PdfTextDirection.rightToLeft,
      alignment: PdfTextAlignment.center,
    );

    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      pen: PdfPen(PdfColor(211, 211, 211)),
      bounds: Rect.fromLTWH(0, 95, page.getClientSize().width, 30),
    );

    graphics.drawString(
      '\nDADOS DO RECIBO',
      font1,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(
        0,
        86.5,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: format,
    );
  }

  // ---------------------------------------------------------------------------
  // Budget data grid
  // ---------------------------------------------------------------------------

  double _drawBudgetDataGrid(PdfPage page, CustomerInfo customer) {
    double count = 0;
    try {
      final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
      pdfGrid.headers.clear();

      void addRow(String label, String? value) {
        if (value == null || value.isEmpty) return;
        final PdfGridRow row = pdfGrid.rows.add();
        row.cells[0].value = label;
        row.cells[1].value = value;
      }

      addRow('Número do orçamento:', customer.id);
      addRow('Cliente :', customer.customerName);

      // Mantém a contagem de linhas extras para deslocamento vertical,
      // equivalente ao comportamento original.
      if (customer.phone != null && customer.phone!.isNotEmpty) {
        addRow('Telefone :', customer.phone);
        count += 10;
      }

      final PdfGridCellStyle style = PdfGridCellStyle()
        ..borders.all = PdfPens.transparent;

      for (int i = 0; i < pdfGrid.rows.count; i++) {
        final PdfGridRow row = pdfGrid.rows[i];
        for (int j = 0; j < row.cells.count; j++) {
          row.cells[j].style = style;
        }
      }

      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.regular,
      );
      final PdfGridCellStyle headerStyle = PdfGridCellStyle(
        font: font,
        textBrush: PdfBrushes.black,
        textPen: PdfPens.white,
      );
      pdfGrid.headers.applyStyle(headerStyle);
      pdfGrid.columns[0].width = 110;
      pdfGrid.columns[1].width = 360;
      pdfGrid.draw(
        graphics: page.graphics,
        bounds: Rect.fromLTWH(
          page.getClientSize().width / 2,
          135,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
      );
    } catch (_) {
      rethrow;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Receipt info grid
  // ---------------------------------------------------------------------------

  void _drawReceiptInfoGrid(PdfPage page, Receipt recived) {
    try {
      final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
      pdfGrid.headers.clear();

      void addRow(String label, String? value) {
        if (value == null || value.isEmpty) return;
        final PdfGridRow row = pdfGrid.rows.add();
        row.cells[0].value = label;
        row.cells[1].value = value;
      }

      addRow('Número do recibo:', recived.id);
      addRow('Data do recibo :', recived.data);
      addRow('Nome do recibo :', recived.descricao);

      final PdfGridCellStyle style = PdfGridCellStyle()
        ..borders.all = PdfPens.transparent;

      for (int i = 0; i < pdfGrid.rows.count; i++) {
        final PdfGridRow row = pdfGrid.rows[i];
        for (int j = 0; j < row.cells.count; j++) {
          row.cells[j].style = style;
        }
      }

      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.regular,
      );
      final PdfGridCellStyle headerStyle = PdfGridCellStyle(
        font: font,
        textBrush: PdfBrushes.black,
        textPen: PdfPens.white,
      );
      pdfGrid.headers.applyStyle(headerStyle);
      pdfGrid.columns[0].width = 70;
      pdfGrid.columns[1].width = 360;
      pdfGrid.draw(
        graphics: page.graphics,
        bounds: Rect.fromLTWH(
          0,
          135,
          page.getClientSize().width,
          page.getClientSize().height,
        ),
      );
    } catch (_) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Payments section title
  // ---------------------------------------------------------------------------

  void _drawPaymentsSectionTitle(
    PdfPage page,
    PdfGraphics graphics,
    double count,
  ) {
    final PdfFont font1 = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final PdfStringFormat format = PdfStringFormat(
      textDirection: PdfTextDirection.rightToLeft,
      alignment: PdfTextAlignment.center,
    );

    graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      pen: PdfPen(PdfColor(211, 211, 211)),
      bounds: Rect.fromLTWH(0, 180 + count, page.getClientSize().width, 30),
    );

    graphics.drawString(
      'PAGAMENTOS REALIZADOS',
      font1,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(
        0,
        187 + count,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: format,
    );
  }

  // ---------------------------------------------------------------------------
  // Payments table
  // ---------------------------------------------------------------------------

  void _drawPaymentsTable({
    required PdfPage page,
    required double count,
    required List<PaymentCustomer> paymentList,
    required String totalPriceBudget,
  }) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);

    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'Descrição dos pagamentos';
    header.cells[1].value = 'Metodo de pagamento';
    header.cells[2].value = 'Valor pago';

    final PdfFont fontHeader = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: fontHeader,
      backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;

    header.height = 25;
    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 200;
    grid.columns[1].width = 180;
    grid.columns[2].width = 105;

    for (final payment in paymentList) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = payment.DESCRICAO!;
      row.cells[1].value = payment.METODO!;
      row.cells[2].value = _moneyConvert.convertFromDouble(payment.PRECO!);
    }

    _applyRowStyle(grid, _createPaymentRowStyle());

    _addTotalRow(
      grid: grid,
      labelCellIndex: 1,
      valueCellIndex: 2,
      label: 'Valor total pago:',
      value: totalPriceBudget,
      style: _createPaymentTotalRowStyle(),
      height: 30,
    );

    grid.draw(
      page: page,
      format: _paginateLayoutFormat(),
      bounds: Rect.fromLTWH(
        0,
        220 + count,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PdfGridCellStyle _createPaymentRowStyle() {
    final PdfGridCellStyle style = PdfGridCellStyle()
      ..cellPadding = PdfPaddings(top: 5, left: 5, right: 5, bottom: 5)
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;
    return style;
  }

  PdfGridCellStyle _createPaymentTotalRowStyle() {
    final PdfGridCellStyle style = PdfGridCellStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
      backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.transparent;
    return style;
  }

  void _addTotalRow({
    required PdfGrid grid,
    required int labelCellIndex,
    required int valueCellIndex,
    required String label,
    required String value,
    required PdfGridCellStyle style,
    required double height,
  }) {
    final PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[labelCellIndex].value = label;
    totalRow.cells[valueCellIndex].value = value;
    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = style;
    }
    totalRow.height = height;
    totalRow.style = style;
  }

  void _applyRowStyle(PdfGrid grid, PdfGridCellStyle style) {
    for (int i = 0; i < grid.rows.count; i++) {
      final PdfGridRow row = grid.rows[i];
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style = style;
      }
    }
  }

  PdfLayoutFormat _paginateLayoutFormat() {
    return PdfLayoutFormat(
      breakType: PdfLayoutBreakType.fitPage,
      layoutType: PdfLayoutType.paginate,
    );
  }

  Future<String> _saveDocument(PdfDocument document) async {
    final directory = await getApplicationSupportDirectory();
    final String path = directory.path;
    final File file = File('$path/${budget.IDORCAMENTO}.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/${budget.IDORCAMENTO}.pdf';
  }
}
