import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:oflite/shared/design_pattern/result.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_logo/pdf_logo_fit.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_text/pdf_sanitize_text_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/pdf_text/pdf_add_wrapped_rows_usecase.dart';
import 'package:oflite/modules/receipt/data/model/payment_customer.dart';
import 'package:oflite/modules/receipt/data/model/receipt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do recibo (dados do titular, dados do orçamento,
/// dados do recibo e tabela de pagamentos realizados).
class PdfGenerateReceiptUseCase {
  final ConvertCoinRepository _moneyConvert;
  final PdfRepository _pdfRepository;
  final PdfSanitizeTextUsecase _sanitizeText;
  final PdfAddWrappedRowsUsecase _addWrappedRows;

  PdfGenerateReceiptUseCase(
    this._moneyConvert,
    this._pdfRepository,
    this._sanitizeText,
    this._addWrappedRows,
  );

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

      final Size logoSize = await _drawLogo(page, owner);

      final double ownerBottomY = _drawOwnerGrid(page, owner, logoSize.width);
      // Cabeçalho dinâmico: a faixa "RECIBO" fica logo abaixo do que for mais
      // alto (logo ou dados da empresa). [offset] desloca todas as seções
      // abaixo em relação à posição original da faixa (95).
      final double titleY = math.max(logoSize.height, ownerBottomY) + 8;
      final double offset = titleY - 95;
      _drawReceiptTitle(page, graphics, titleY);
      final double count =
          _drawBudgetDataGrid(page, customer, titleY + 40) + offset;
      _drawReceiptInfoGrid(page, recived, titleY + 40);

      _drawPaymentsSectionTitle(page, graphics, count);

      if (paymentList.isNotEmpty) {
        _drawPaymentsTable(
          page: page,
          count: count,
          paymentList: paymentList,
          totalPriceBudget: totalPriceBudget,
        );
      }

      final String localFile = await _saveDocument(document, customer.id!);
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
    final PdfDocument document =
        PdfDocument()
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

  /// Desenha a logo e retorna o tamanho ocupado (zero quando não há logo).
  Future<Size> _drawLogo(PdfPage page, OwnerPdf owner) async {
    PdfBitmap? image;
    try {
      final logo = await _pdfRepository.fetchLogo(owner);
      if (logo case Ok<Uint8List?>(:final value?)) image = PdfBitmap(value);
      if (logo case Error<Uint8List?>(:final error)) throw error;
    } catch (_) {
      // Web: falha no logo (CORS/rede) não derruba o PDF — segue sem logo.
      if (!kIsWeb) rethrow;
    }
    if (image == null) return Size.zero;

    // Encaixa a logo em 140x80 mantendo a proporção (sem esticar).
    final Size logo = fitLogoSize(
      image.width,
      image.height,
      maxW: 140,
      maxH: 80,
    );
    final double sizeWithImage = logo.width + 10;

    page.graphics.drawImage(image, Rect.fromLTWH(0, 0, logo.width, logo.height));
    return Size(sizeWithImage, logo.height);
  }

  // ---------------------------------------------------------------------------
  // Owner info grid
  // ---------------------------------------------------------------------------

  /// Desenha os dados da empresa e retorna o Y final do bloco.
  double _drawOwnerGrid(PdfPage page, OwnerPdf owner, double sizeWithImage) {
    final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
    pdfGrid.headers.clear();

    void addRow(String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = pdfGrid.rows.add();
      row.cells[0].value = _sanitizeText(value);
    }

    addRow(owner.empresa);
    addRow(owner.cnpj);
    addRow(owner.email);
    addRow(owner.fone);
    // Endereço no mesmo formato do layout Profissional:
    // "Endereço: RUA - BAIRRO - CIDADE - CEP: 00000-000".
    final addressParts = <String>[];
    if (owner.rua != null && owner.rua!.isNotEmpty) {
      addressParts.add(owner.rua!);
    }
    if (owner.bairro != null && owner.bairro!.isNotEmpty) {
      addressParts.add(owner.bairro!);
    }
    if (owner.city != null && owner.city!.isNotEmpty) {
      addressParts.add(owner.city!);
    }
    if (owner.cep != null && owner.cep!.isNotEmpty) {
      addressParts.add('CEP: ${owner.cep}');
    }
    if (addressParts.isNotEmpty) {
      addRow('Endereço: ${addressParts.join(' - ')}');
    }

    final PdfGridCellStyle style =
        PdfGridCellStyle()..borders.all = PdfPens.transparent;

    for (int i = 0; i < pdfGrid.rows.count; i++) {
      final PdfGridRow row = pdfGrid.rows[i];
      row.style.font =
          i == 0
              ? PdfStandardFont(
                PdfFontFamily.helvetica,
                12,
                style: PdfFontStyle.bold,
              )
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
    // Desenhar com `page:` (e não `graphics:`): só assim o Syncfusion
    // devolve o PdfLayoutResult com a altura real do bloco.
    final PdfLayoutResult? result = pdfGrid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        sizeWithImage,
        0,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );
    return result?.bounds.bottom ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Receipt section title
  // ---------------------------------------------------------------------------

  void _drawReceiptTitle(PdfPage page, PdfGraphics graphics, double top) {
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
      bounds: Rect.fromLTWH(0, top, page.getClientSize().width, 30),
    );

    graphics.drawString(
      _sanitizeText('\nDADOS DO RECIBO'),
      font1,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(
        0,
        top - 8.5,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: format,
    );
  }

  // ---------------------------------------------------------------------------
  // Budget data grid
  // ---------------------------------------------------------------------------

  double _drawBudgetDataGrid(
    PdfPage page,
    CustomerInfo customer,
    double top,
  ) {
    double count = 0;
    try {
      final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
      pdfGrid.headers.clear();

      void addRow(String label, String? value) {
        if (value == null || value.isEmpty) return;
        final PdfGridRow row = pdfGrid.rows.add();
        row.cells[0].value = _sanitizeText(label);
        row.cells[1].value = _sanitizeText(value);
      }

      addRow('Número do orçamento:', customer.id);
      addRow('Cliente :', customer.customerName);

      // Mantém a contagem de linhas extras para deslocamento vertical,
      // equivalente ao comportamento original.
      if (customer.phone != null && customer.phone!.isNotEmpty) {
        addRow('Telefone :', customer.phone);
        count += 10;
      }

      final PdfGridCellStyle style =
          PdfGridCellStyle()..borders.all = PdfPens.transparent;

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
          top,
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

  void _drawReceiptInfoGrid(PdfPage page, Receipt recived, double top) {
    try {
      final PdfGrid pdfGrid = PdfGrid()..columns.add(count: 2);
      pdfGrid.headers.clear();

      void addRow(String label, String? value) {
        if (value == null || value.isEmpty) return;
        final PdfGridRow row = pdfGrid.rows.add();
        row.cells[0].value = _sanitizeText(label);
        row.cells[1].value = _sanitizeText(value);
      }

      addRow('Número do recibo:', recived.id);
      addRow('Data do recibo :', recived.data);
      addRow('Nome do recibo :', recived.descricao);

      final PdfGridCellStyle style =
          PdfGridCellStyle()..borders.all = PdfPens.transparent;

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
          top,
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
      _sanitizeText('PAGAMENTOS REALIZADOS'),
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
    header.cells[0].value = _sanitizeText('Descrição dos pagamentos');
    header.cells[1].value = _sanitizeText('Metodo de pagamento');
    header.cells[2].value = _sanitizeText('Valor pago');

    final PdfFont fontHeader = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle =
        PdfGridCellStyle(
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

    final PdfGridCellStyle rowStyle = _createPaymentRowStyle();
    for (final payment in paymentList) {
      _addWrappedRows(
        grid,
        cells: [
          payment.description!,
          payment.method!,
          _moneyConvert.convertFromDouble(payment.price!),
        ],
        style: rowStyle,
      );
    }

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
    final PdfGridCellStyle style =
        PdfGridCellStyle()
          ..cellPadding = PdfPaddings(top: 5, left: 5, right: 5, bottom: 5)
          ..borders.left = PdfPens.transparent
          ..borders.right = PdfPens.transparent
          ..borders.top = PdfPens.lightGray
          ..borders.bottom = PdfPens.lightGray;
    return style;
  }

  PdfGridCellStyle _createPaymentTotalRowStyle() {
    final PdfGridCellStyle style =
        PdfGridCellStyle(
            font: PdfStandardFont(
              PdfFontFamily.helvetica,
              12,
              style: PdfFontStyle.bold,
            ),
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
    totalRow.cells[labelCellIndex].value = _sanitizeText(label);
    totalRow.cells[valueCellIndex].value = _sanitizeText(value);
    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = style;
    }
    totalRow.height = height;
    totalRow.style = style;
  }

  PdfLayoutFormat _paginateLayoutFormat() {
    return PdfLayoutFormat(
      breakType: PdfLayoutBreakType.fitPage,
      layoutType: PdfLayoutType.paginate,
    );
  }

  Future<String> _saveDocument(PdfDocument document, String filename) async {
    final directory = await getApplicationSupportDirectory();
    final String path = directory.path;
    final File file = File('$path/$filename.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/$filename.pdf';
  }
}
