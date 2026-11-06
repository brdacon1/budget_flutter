import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do orçamento — Layout **Profissional**.
class PdfGenerateBudgetProfessionalUsecase {
  final ConvertCoinRepository _moneyConvert;
  final UserRepository _userRepository;

  PdfGenerateBudgetProfessionalUsecase(
    this._moneyConvert,
    this._userRepository,
  );

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  Future<String> professionalPDF({
    required int countService,
    required int countProduct,
    required String totalPriceBudget,
    required String totalPriceProducts,
    required String totalPriceServices,
    required List<ItemsBudget> items,
    required CustomerInfo customer,
    required OwnerPdf owner,
    required List<ObservationPdf> observations,
    String? authToken,
  }) async {
    try {
      final PdfDocument document = await _buildDocument(
        countService: countService,
        countProduct: countProduct,
        totalPriceBudget: totalPriceBudget,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        items: items,
        customer: customer,
        owner: owner,
        observations: observations,
        authToken: authToken,
      );
      final String localFile = await _saveDocument(document, customer.id!);
      items.clear();
      observations.clear();
      document.dispose();
      return localFile;
    } catch (_) {
      rethrow;
    }
  }

  Future<Uint8List> professionalPDFBytes({
    required int countService,
    required int countProduct,
    required String totalPriceBudget,
    required String totalPriceProducts,
    required String totalPriceServices,
    required List<ItemsBudget> items,
    required CustomerInfo customer,
    required OwnerPdf owner,
    required List<ObservationPdf> observations,
    String? authToken,
  }) async {
    try {
      final PdfDocument document = await _buildDocument(
        countService: countService,
        countProduct: countProduct,
        totalPriceBudget: totalPriceBudget,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        items: items,
        customer: customer,
        owner: owner,
        observations: observations,
        authToken: authToken,
      );
      final List<int> bytes = await document.save();
      items.clear();
      observations.clear();
      document.dispose();
      return Uint8List.fromList(bytes);
    } catch (_) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Cores e fontes reutilizáveis
  // ---------------------------------------------------------------------------

  static final PdfColor _primaryBlue = PdfColor(30, 58, 138); // azul escuro
  static final PdfColor _lightBg = PdfColor(
    240,
    245,
    255,
  ); // fundo leve azulado
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
    required int countService,
    required int countProduct,
    required String totalPriceBudget,
    required String totalPriceProducts,
    required String totalPriceServices,
    required List<ItemsBudget> items,
    required CustomerInfo customer,
    required OwnerPdf owner,
    required List<ObservationPdf> observations,
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

    y = _drawInfoBoxes(page, customer, pageW, y + 12);

    // ── Produtos ──
    if (countProduct > 0) {
      y = _drawSectionTitle(page, 'PRODUTOS', y + 18);
      y = _drawItemsTable(
        page: page,
        topY: y,
        items: items,
        category: 'Produtos',
        descriptionLabel: 'Descrição dos produtos',
        countService: countService,
        countProduct: countProduct,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
    }

    // ── Serviços ──
    if (countService > 0) {
      y = _drawSectionTitle(page, 'SERVIÇOS', y + 14);
      y = _drawItemsTable(
        page: page,
        topY: y,
        items: items,
        category: 'Serviços',
        descriptionLabel: 'Descrição dos serviços',
        countService: countService,
        countProduct: countProduct,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
    }

    // ── Observações (se couber, senão nova página) ──
    if (observations.isNotEmpty) {
      final double obsHeight = 60 + (observations.length * 22);
      if (y + obsHeight > page.getClientSize().height - 40) {
        _drawObservationsNewPage(document, observations, owner, pageW);
      } else {
        y = _drawObservationsSection(page, observations, pageW, y + 18);
      }
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

    if (owner.fotoId != null && owner.fotoId!.isNotEmpty) {
      try {
        final String fotoId = owner.fotoId ?? '';
        final String endpointUrl =
            fotoId.startsWith('http')
                ? fotoId
                : 'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=$fotoId';

        final Map<String, String> headers = <String, String>{
          'Accept': 'application/json;odata=verbose',
        };
        if (!kIsWeb) {
          final String token = await _getAuthToken(authToken);
          headers['Authorization'] = 'Bearer $token';
        }

        final http.Response response = await http.get(
          Uri.parse(endpointUrl),
          headers: headers,
        );

        if (response.statusCode == 200) {
          image = PdfBitmap(response.bodyBytes);
          final double ratio = image.width / image.height;
          if (image.height > image.width) {
            logoW = 55;
            logoH = 70;
          } else {
            logoW = 70 * ratio;
            logoH = 70;
          }
          g.drawImage(image, Rect.fromLTWH(0, 0, logoW, logoH));
        }
      } catch (_) {
        if (!kIsWeb) rethrow;
      }
    }

    final double textX = logoW > 0 ? logoW + 12 : 0;
    double y = 0;

    // Nome empresa — azul escuro, grande
    if (owner.empresa != null && owner.empresa!.isNotEmpty) {
      g.drawString(
        owner.empresa!,
        _fontTitle,
        brush: _brushPrimary,
        bounds: Rect.fromLTWH(textX, y, pageW - textX, 24),
      );
      y += 22;
    }

    final PdfFont infoFont = _fontRegular;
    final PdfBrush infoBrush = _brushGray;

    void _infoLine(String label, String? value) {
      if (value == null || value.isEmpty) return;
      g.drawString(
        '$label $value',
        infoFont,
        brush: infoBrush,
        bounds: Rect.fromLTWH(textX, y, pageW - textX, 13),
      );
      y += 12;
    }

    _infoLine('CNPJ/CPF:', owner.cnpj);
    _infoLine('E-mail:', owner.email);
    _infoLine('Telefone:', owner.fone);

    final addressParts = <String>[];
    if (owner.rua != null && owner.rua!.isNotEmpty)
      addressParts.add(owner.rua!);
    if (owner.bairro != null && owner.bairro!.isNotEmpty)
      addressParts.add(owner.bairro!);
    if (owner.city != null && owner.city!.isNotEmpty)
      addressParts.add(owner.city!);
    if (owner.cep != null && owner.cep!.isNotEmpty)
      addressParts.add('CEP: ${owner.cep}');
    if (addressParts.isNotEmpty) {
      _infoLine('Endereço:', addressParts.join(' - '));
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
    double pageW,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;
    final double gap = 14;
    final double boxW = (pageW - gap) / 2;
    const double pad = 10;

    final PdfPen borderPen = PdfPen(_borderGray, width: 0.5);
    final PdfBrush bgBrush = PdfSolidBrush(PdfColor(250, 250, 250));

    // ── Box esquerdo: DADOS DO ORÇAMENTO ──
    final double leftH = _boxContentHeight([
      _BoxRow('Número:', customer.id),
      _BoxRow('Criado em:', customer.data),
    ]);
    _drawBox(g, 0, topY, boxW, leftH + pad * 2 + 22, borderPen, bgBrush);
    _drawBoxTitle(g, 'DADOS DO ORÇAMENTO', 0, topY, boxW, pad);
    _drawBoxRows(
      g,
      [_BoxRow('Número:', customer.id), _BoxRow('Criado em:', customer.data)],
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
      title,
      _fontSectionTitle,
      brush: _brushPrimary,
      bounds: Rect.fromLTWH(x + pad, y + pad, w - pad * 2, 16),
    );
    // linha abaixo do título
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
        row.label,
        _fontRegular,
        brush: _brushGray,
        bounds: Rect.fromLTWH(xOffset + pad, y, contentW * 0.4, 13),
      );
      g.drawString(
        row.value!,
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

    // barra vertical azul
    g.drawRectangle(
      brush: _brushPrimary,
      bounds: Rect.fromLTWH(0, topY + 2, barW, barH),
    );

    // fundo azul bem claro
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
      title,
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
  // Tabela de itens
  // ---------------------------------------------------------------------------

  double _drawItemsTable({
    required PdfPage page,
    required double topY,
    required List<ItemsBudget> items,
    required String category,
    required String descriptionLabel,
    required int countService,
    required int countProduct,
    String? totalPriceProducts,
    String? totalPriceServices,
    required String totalPriceBudget,
  }) {
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);

    // Header
    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = descriptionLabel;
    header.cells[1].value = 'Medida';
    header.cells[2].value = 'Qtd';
    header.cells[3].value = 'Preço';
    header.cells[4].value = 'Total';

    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: _fontHeader,
      backgroundBrush: _brushPrimary,
      textBrush: _brushWhite,
      cellPadding: PdfPaddings(top: 6, left: 6, right: 6, bottom: 6),
    )..borders.all = PdfPens.transparent;

    grid.headers.applyStyle(headerStyle);
    header.height = 26;

    // Larguras
    grid.columns[0].width = 210;
    grid.columns[1].width = 75;
    grid.columns[2].width = 55;
    grid.columns[3].width = 100;
    grid.columns[4].width = 95;

    // Linhas
    for (final item in items) {
      if (item.CATEGORIA == category) {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = item.DESCRICAO ?? '';
        row.cells[1].value = item.MEDIDA ?? '';
        row.cells[2].value = (item.QTD ?? 0).toString();
        row.cells[3].value = _moneyConvert.convertFromDouble(item.PRECO ?? 0);
        row.cells[4].value = _moneyConvert.convertFromDouble(item.TOTAL ?? 0);
      }
    }

    _applyRowStyle(grid, _itemRowStyle());

    // Total parcial
    if (category == 'Produtos' && totalPriceProducts != null) {
      _addRightAlignedTotalRow(
        grid: grid,
        label: 'Valor de produtos:',
        value: totalPriceProducts,
        font: _fontRegular,
        textBrush: _brushBlack,
        bgBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
      );
    }
    if (category == 'Serviços' && totalPriceServices != null) {
      if (countProduct > 0) {
        _addRightAlignedTotalRow(
          grid: grid,
          label: 'Valor de produtos:',
          value: totalPriceProducts ?? '',
          font: _fontRegular,
          textBrush: _brushBlack,
          bgBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
        );
      }
      _addRightAlignedTotalRow(
        grid: grid,
        label: 'Valor de serviços:',
        value: totalPriceServices,
        font: _fontRegular,
        textBrush: _brushBlack,
        bgBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
      );
    }

    // Total geral (se for última tabela)
    final bool isLast =
        (category == 'Produtos' && countService == 0) ||
        (category == 'Serviços');

    if (isLast) {
      _addRightAlignedTotalRow(
        grid: grid,
        label: 'VALOR TOTAL:',
        value: totalPriceBudget,
        font: _fontTotal,
        textBrush: _brushWhite,
        bgBrush: _brushPrimary,
      );
    }

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
    row.cells[3].value = label;
    row.cells[4].value = value;

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
  // Observações (na mesma página)
  // ---------------------------------------------------------------------------

  double _drawObservationsSection(
    PdfPage page,
    List<ObservationPdf> observations,
    double pageW,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;

    double y = _drawSectionTitle(page, 'OBSERVAÇÕES DO ORÇAMENTO', topY);

    final PdfGrid grid = PdfGrid()..columns.add(count: 2);
    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'Data';
    header.cells[1].value = 'Observação';

    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: _fontHeader,
      backgroundBrush: _brushPrimary,
      textBrush: _brushWhite,
      cellPadding: PdfPaddings(top: 6, left: 6, right: 6, bottom: 6),
    )..borders.all = PdfPens.transparent;

    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 75;
    grid.columns[1].width = pageW - 75;

    for (final obs in observations) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = obs.data;
      row.cells[1].value = obs.observacao;
    }

    _applyRowStyle(grid, _itemRowStyle());

    final PdfLayoutResult result =
        grid.draw(
              page: page,
              bounds: Rect.fromLTWH(0, y, pageW, page.getClientSize().height),
              format: PdfLayoutFormat(
                breakType: PdfLayoutBreakType.fitPage,
                layoutType: PdfLayoutType.paginate,
              ),
            )
            as PdfLayoutResult;

    return result.bounds.bottom;
  }

  // ---------------------------------------------------------------------------
  // Observações (nova página)
  // ---------------------------------------------------------------------------

  void _drawObservationsNewPage(
    PdfDocument document,
    List<ObservationPdf> observations,
    OwnerPdf owner,
    double pageW,
  ) {
    final PdfPage page = document.pages.add();
    _drawObservationsSection(page, observations, pageW, 10);
    _drawFooter(page, owner, pageW);
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  void _drawFooter(PdfPage page, OwnerPdf owner, double pageW) {
    final PdfGraphics g = page.graphics;
    final double y = page.getClientSize().height - 24;

    // Linha cinza
    g.drawLine(PdfPen(_borderGray, width: 0.5), Offset(0, y), Offset(pageW, y));

    // Esquerda
    g.drawString(
      '${owner.empresa ?? ''} • Orçamento Comercial',
      _fontSmall,
      brush: _brushGray,
      bounds: Rect.fromLTWH(0, y + 4, pageW * 0.5, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    // Direita — página
    g.drawString(
      'Page 1 of 1',
      _fontSmall,
      brush: _brushGray,
      bounds: Rect.fromLTWH(pageW * 0.5, y + 4, pageW * 0.5, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  // ---------------------------------------------------------------------------
  // Autenticação
  // ---------------------------------------------------------------------------

  Future<String> _getAuthToken(String? authToken) async {
    if (authToken != null && authToken.isNotEmpty) return authToken;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final token = await currentUser.getIdToken();
      if (token != null && token.isNotEmpty) return token;
    }
    final session = _userRepository.selectUser.value;
    if (session == null) return '';
    if (session.googleAuth == true) return '';
    if (session.EMAIL == null ||
        session.EMAIL!.isEmpty ||
        session.Senha == null ||
        session.Senha!.isEmpty)
      return '';
    final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: session.EMAIL!.trim(),
      password: session.Senha!.trim(),
    );
    return (await auth.user?.getIdToken()) ?? '';
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

  void _applyRowStyle(PdfGrid grid, PdfGridCellStyle style) {
    for (int i = 0; i < grid.rows.count; i++) {
      final PdfGridRow row = grid.rows[i];
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style = style;
      }
    }
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
