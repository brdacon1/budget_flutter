import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

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

/// Geração do PDF de recibo — Layout **Profissional**.
///
/// Referência visual (baseada no orçamento profissional):
/// - Cabeçalho claro com logo, dados da empresa e linha azul separadora.
/// - Dois boxes lado a lado: Dados do Recibo e Dados do Cliente.
/// - Seção de pagamentos com título e barra vertical azul.
/// - Tabela de pagamentos com headers em português natural.
/// - Valor total com fundo azul escuro e texto branco.
/// - Rodapé com linha cinza.
class PdfGenerateReceiptProfessionalUsecase {
  final ConvertCoinRepository _moneyConvert;
  final PdfRepository _pdfRepository;
  final PdfSanitizeTextUsecase _sanitizeText;
  final PdfAddWrappedRowsUsecase _addWrappedRows;

  PdfGenerateReceiptProfessionalUsecase(
    this._moneyConvert,
    this._pdfRepository,
    this._sanitizeText,
    this._addWrappedRows,
  );

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  Future<String> professionalPDF({
    required List<PaymentCustomer> paymentList,
    required Receipt recived,
    required String totalPriceBudget,
    required CustomerInfo customer,
    required OwnerPdf owner,
    String? authToken,
  }) async {
    try {
      final PdfDocument document = await _buildDocument(
        paymentList: paymentList,
        recived: recived,
        totalPriceBudget: totalPriceBudget,
        customer: customer,
        owner: owner,
        authToken: authToken,
      );
      final String localFile = await _saveDocument(
        document,
        recived.id ?? 'recibo',
      );
      document.dispose();
      return localFile;
    } catch (_) {
      rethrow;
    }
  }

  Future<Uint8List> professionalPDFBytes({
    required List<PaymentCustomer> paymentList,
    required Receipt recived,
    required String totalPriceBudget,
    required CustomerInfo customer,
    required OwnerPdf owner,
    String? authToken,
  }) async {
    try {
      final PdfDocument document = await _buildDocument(
        paymentList: paymentList,
        recived: recived,
        totalPriceBudget: totalPriceBudget,
        customer: customer,
        owner: owner,
        authToken: authToken,
      );
      final List<int> bytes = await document.save();
      document.dispose();
      return Uint8List.fromList(bytes);
    } catch (_) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Cores e fontes reutilizáveis
  // ---------------------------------------------------------------------------

  static final PdfColor _primaryBlue = PdfColor(30, 58, 138);
  static final PdfColor _lightBg = PdfColor(240, 245, 255);
  static final PdfColor _borderGray = PdfColor(220, 220, 220);

  PdfFont get _fontTitle =>
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);

  PdfFont get _fontSectionTitle =>
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold);

  PdfFont get _fontHeader =>
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);

  PdfFont get _fontRegular =>
      PdfStandardFont(PdfFontFamily.helvetica, 9, style: PdfFontStyle.regular);

  PdfFont get _fontSmall =>
      PdfStandardFont(PdfFontFamily.helvetica, 8, style: PdfFontStyle.regular);

  PdfFont get _fontTotal =>
      PdfStandardFont(PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold);

  PdfBrush get _brushPrimary => PdfSolidBrush(_primaryBlue);

  PdfBrush get _brushWhite => PdfBrushes.white;

  PdfBrush get _brushBlack => PdfBrushes.black;

  PdfBrush get _brushGray => PdfSolidBrush(PdfColor(100, 100, 100));

  // ---------------------------------------------------------------------------
  // Documento
  // ---------------------------------------------------------------------------

  Future<PdfDocument> _buildDocument({
    required List<PaymentCustomer> paymentList,
    required Receipt recived,
    required String totalPriceBudget,
    required CustomerInfo customer,
    required OwnerPdf owner,
    String? authToken,
  }) async {
    final PdfDocument document =
        PdfDocument()
          ..pageSettings.size = PdfPageSize.a4
          ..pageSettings.margins.left = 30
          ..pageSettings.margins.right = 30
          ..pageSettings.margins.top = 30
          ..pageSettings.margins.bottom = 50;

    final PdfPage page = document.pages.add();
    final double pageW = page.getClientSize().width;

    double y = await _drawHeader(page, owner, authToken, pageW);

    y = _drawInfoBoxes(page, customer, recived, pageW, y + 12);

    if (paymentList.isNotEmpty) {
      y = _drawSectionTitle(page, 'PAGAMENTOS REALIZADOS', y + 18);
      y = _drawPaymentsTable(
        page: page,
        topY: y,
        paymentList: paymentList,
        totalPriceBudget: totalPriceBudget,
      );
    }

    _drawFooter(page, owner, pageW);
    return document;
  }

  // ---------------------------------------------------------------------------
  // Header — logo + dados da empresa + linha azul
  // ---------------------------------------------------------------------------

  Future<double> _drawHeader(
    PdfPage page,
    OwnerPdf owner,
    String? authToken,
    double pageW,
  ) async {
    final PdfGraphics g = page.graphics;
    double logoH = 0;
    double logoW = 0;

    PdfBitmap? image;
    try {
      final logo = await _pdfRepository.fetchLogo(owner, authToken: authToken);
      if (logo case Ok<Uint8List?>(:final value?)) image = PdfBitmap(value);
      if (logo case Error<Uint8List?>(:final error)) throw error;
    } catch (_) {
      // Web: falha no logo (CORS/rede) não derruba o PDF — segue sem logo.
      if (!kIsWeb) rethrow;
    }
    if (image != null) {
      // Encaixa a logo em 120x70 mantendo a proporção (sem esticar).
      final logo = fitLogoSize(image.width, image.height, maxW: 120, maxH: 70);
      logoW = logo.width;
      logoH = logo.height;
      g.drawImage(image, Rect.fromLTWH(0, 0, logoW, logoH));
    }

    final double textX = logoW > 0 ? logoW + 12 : 0;
    double y = 0;

    if (owner.empresa != null && owner.empresa!.isNotEmpty) {
      g.drawString(
        _sanitizeText(owner.empresa!),
        _fontTitle,
        brush: _brushPrimary,
        bounds: Rect.fromLTWH(textX, y, pageW - textX, 24),
      );
      y += 22;
    }

    final PdfFont infoFont = _fontRegular;
    final PdfBrush infoBrush = _brushGray;

    void infoLine(String label, String? value) {
      if (value == null || value.isEmpty) return;
      g.drawString(
        _sanitizeText('$label $value'),
        infoFont,
        brush: infoBrush,
        bounds: Rect.fromLTWH(textX, y, pageW - textX, 13),
      );
      y += 12;
    }

    infoLine('CNPJ/CPF:', owner.cnpj);
    infoLine('E-mail:', owner.email);
    infoLine('Telefone:', owner.fone);

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
      infoLine('Endereço:', addressParts.join(' - '));
    }

    final double headerBottom = (logoH > y) ? logoH : y;

    // Linha azul separadora
    g.drawLine(
      PdfPen(_primaryBlue, width: 2),
      Offset(0, headerBottom + 6),
      Offset(pageW, headerBottom + 6),
    );

    return headerBottom + 14;
  }

  // ---------------------------------------------------------------------------
  // Caixas de informação lado a lado
  // ---------------------------------------------------------------------------

  double _drawInfoBoxes(
    PdfPage page,
    CustomerInfo customer,
    Receipt recived,
    double pageW,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;
    final double gap = 14;
    final double boxW = (pageW - gap) / 2;
    const double pad = 10;

    final PdfPen borderPen = PdfPen(_borderGray, width: 0.5);
    final PdfBrush bgBrush = PdfSolidBrush(PdfColor(250, 250, 250));

    // ── Box esquerdo: DADOS DO RECIBO ──
    final double leftH = _boxContentHeight([
      _BoxRow('Número:', recived.id),
      _BoxRow('Data:', recived.data),
      _BoxRow('Descrição:', recived.descricao),
    ]);
    _drawBox(g, 0, topY, boxW, leftH + pad * 2 + 22, borderPen, bgBrush);
    _drawBoxTitle(g, 'DADOS DO RECIBO', 0, topY, boxW, pad);
    _drawBoxRows(
      g,
      [
        _BoxRow('Número:', recived.id),
        _BoxRow('Data:', recived.data),
        _BoxRow('Descrição:', recived.descricao),
      ],
      pad,
      topY + 22,
      boxW - pad * 2,
    );

    // ── Box direito: DADOS DO CLIENTE ──
    final double rightH = _boxContentHeight([
      _BoxRow('Cliente:', customer.customerName),
      _BoxRow('Telefone:', customer.phone),
      _BoxRow('Endereço:', customer.street),
      if (customer.city != null && customer.city!.isNotEmpty)
        _BoxRow(
          'Cidade / CEP:',
          '${customer.city}${customer.zip != null && customer.zip!.isNotEmpty ? ' - ${customer.zip}' : ''}',
        ),
    ]);
    _drawBox(
      g,
      boxW + gap,
      topY,
      boxW,
      rightH + pad * 2 + 22,
      borderPen,
      bgBrush,
    );
    _drawBoxTitle(g, 'DADOS DO CLIENTE', boxW + gap, topY, boxW, pad);
    _drawBoxRows(
      g,
      [
        _BoxRow('Cliente:', customer.customerName),
        _BoxRow('Telefone:', customer.phone),
        _BoxRow('Endereço:', customer.street),
        if (customer.city != null && customer.city!.isNotEmpty)
          _BoxRow(
            'Cidade / CEP:',
            '${customer.city}${customer.zip != null && customer.zip!.isNotEmpty ? ' - ${customer.zip}' : ''}',
          ),
      ],
      pad,
      topY + 22,
      boxW - pad * 2,
      xOffset: boxW + gap,
    );

    return topY + (leftH > rightH ? leftH : rightH) + pad * 2 + 22;
  }

  void _drawBox(
    PdfGraphics g,
    double x,
    double y,
    double w,
    double h,
    PdfPen border,
    PdfBrush? bg,
  ) {
    if (bg != null) {
      g.drawRectangle(brush: bg, bounds: Rect.fromLTWH(x, y, w, h));
    }
    g.drawRectangle(pen: border, bounds: Rect.fromLTWH(x, y, w, h));
  }

  void _drawBoxTitle(
    PdfGraphics g,
    String title,
    double x,
    double y,
    double w,
    double pad,
  ) {
    g.drawString(
      _sanitizeText(title),
      _fontSectionTitle,
      brush: _brushPrimary,
      bounds: Rect.fromLTWH(x + pad, y + pad, w - pad * 2, 16),
    );
    g.drawLine(
      PdfPen(_borderGray, width: 0.5),
      Offset(x + pad, y + pad + 16),
      Offset(x + w - pad, y + pad + 16),
    );
  }

  void _drawBoxRows(
    PdfGraphics g,
    List<_BoxRow> rows,
    double pad,
    double startY,
    double contentW, {
    double xOffset = 0,
  }) {
    double y = startY + pad;
    for (final row in rows) {
      if (row.value == null || row.value!.isEmpty) continue;
      g.drawString(
        _sanitizeText(row.label),
        _fontRegular,
        brush: _brushGray,
        bounds: Rect.fromLTWH(xOffset + pad, y, contentW * 0.4, 13),
      );
      g.drawString(
        _sanitizeText(row.value!),
        _fontRegular,
        brush: _brushBlack,
        bounds: Rect.fromLTWH(
          xOffset + pad + contentW * 0.4,
          y,
          contentW * 0.6,
          13,
        ),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      y += 13;
    }
  }

  double _boxContentHeight(List<_BoxRow> rows) {
    int valid = 0;
    for (final r in rows) {
      if (r.value != null && r.value!.isNotEmpty) valid++;
    }
    return valid * 13.0;
  }

  // ---------------------------------------------------------------------------
  // Título de seção com barra azul vertical
  // ---------------------------------------------------------------------------

  double _drawSectionTitle(PdfPage page, String title, double topY) {
    final PdfGraphics g = page.graphics;
    const double barW = 4;
    const double barH = 20;

    g.drawRectangle(
      brush: _brushPrimary,
      bounds: Rect.fromLTWH(0, topY + 2, barW, barH),
    );

    g.drawRectangle(
      brush: PdfSolidBrush(_lightBg),
      bounds: Rect.fromLTWH(
        barW + 4,
        topY,
        page.getClientSize().width - barW - 4,
        barH + 4,
      ),
    );

    g.drawString(
      _sanitizeText(title),
      _fontSectionTitle,
      brush: _brushPrimary,
      bounds: Rect.fromLTWH(
        barW + 10,
        topY + 3,
        page.getClientSize().width - barW - 14,
        barH,
      ),
    );

    return topY + barH + 8;
  }

  // ---------------------------------------------------------------------------
  // Tabela de pagamentos
  // ---------------------------------------------------------------------------

  double _drawPaymentsTable({
    required PdfPage page,
    required double topY,
    required List<PaymentCustomer> paymentList,
    required String totalPriceBudget,
  }) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 3);

    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = _sanitizeText('Descrição dos pagamentos');
    header.cells[1].value = _sanitizeText('Método');
    header.cells[2].value = _sanitizeText('Valor pago');

    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: _fontHeader,
      backgroundBrush: _brushPrimary,
      textBrush: _brushWhite,
      cellPadding: PdfPaddings(top: 6, left: 6, right: 6, bottom: 6),
    )..borders.all = PdfPens.transparent;

    grid.headers.applyStyle(headerStyle);
    header.height = 26;

    grid.columns[0].width = 260;
    grid.columns[1].width = 160;
    grid.columns[2].width = 115;

    final PdfGridCellStyle rowStyle = _itemRowStyle();
    for (final payment in paymentList) {
      _addWrappedRows(
        grid,
        cells: [
          payment.description ?? '',
          payment.method ?? '',
          _moneyConvert.convertFromDouble(payment.price ?? 0),
        ],
        style: rowStyle,
      );
    }

    _addRightAlignedTotalRow(
      grid: grid,
      label: 'VALOR TOTAL PAGO:',
      value: totalPriceBudget,
      font: _fontTotal,
      textBrush: _brushWhite,
      bgBrush: _brushPrimary,
    );

    final PdfLayoutResult result =
        grid.draw(
              page: page,
              bounds: Rect.fromLTWH(
                0,
                topY,
                page.getClientSize().width,
                page.getClientSize().height,
              ),
              format: PdfLayoutFormat(
                breakType: PdfLayoutBreakType.fitPage,
                layoutType: PdfLayoutType.paginate,
              ),
            )
            as PdfLayoutResult;

    return result.bounds.bottom;
  }

  void _addRightAlignedTotalRow({
    required PdfGrid grid,
    required String label,
    required String value,
    required PdfFont font,
    required PdfBrush textBrush,
    required PdfBrush bgBrush,
  }) {
    final PdfGridRow row = grid.rows.add();
    row.cells[1].value = _sanitizeText(label);
    row.cells[2].value = _sanitizeText(value);

    final PdfGridCellStyle style = PdfGridCellStyle(
      font: font,
      textBrush: textBrush,
      backgroundBrush: bgBrush,
      cellPadding: PdfPaddings(top: 5, left: 6, right: 6, bottom: 5),
    )..borders.all = PdfPens.transparent;

    for (int i = 0; i < row.cells.count; i++) {
      row.cells[i].style = style;
    }
    row.height = 24;
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  void _drawFooter(PdfPage page, OwnerPdf owner, double pageW) {
    final PdfGraphics g = page.graphics;
    final double y = page.getClientSize().height - 24;

    g.drawLine(PdfPen(_borderGray, width: 0.5), Offset(0, y), Offset(pageW, y));

    g.drawString(
      _sanitizeText('${owner.empresa ?? ''} • Recibo Comercial'),
      _fontSmall,
      brush: _brushGray,
      bounds: Rect.fromLTWH(0, y + 4, pageW * 0.5, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    g.drawString(
      _sanitizeText('Página 1 de 1'),
      _fontSmall,
      brush: _brushGray,
      bounds: Rect.fromLTWH(pageW * 0.5, y + 4, pageW * 0.5, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PdfGridCellStyle _itemRowStyle() {
    return PdfGridCellStyle(
        font: _fontRegular,
        cellPadding: PdfPaddings(top: 5, left: 6, right: 6, bottom: 5),
      )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPen(_borderGray, width: 0.5)
      ..borders.bottom = PdfPen(_borderGray, width: 0.5);
  }

  Future<String> _saveDocument(PdfDocument document, String filename) async {
    final directory = await getTemporaryDirectory();
    final String path = directory.path;
    final File file = File('$path/$filename.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/$filename.pdf';
  }
}

// ---------------------------------------------------------------------------
// Modelo auxiliar
// ---------------------------------------------------------------------------

class _BoxRow {
  final String label;
  final String? value;

  _BoxRow(this.label, this.value);
}
