import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Resultado de desenho de uma tabela para permitir continuar na página correta.
class _TableResult {
  final PdfPage page;
  final double y;
  _TableResult(this.page, this.y);
}

/// Geração do PDF do orçamento — Layout **Executivo**.
///
/// Referência visual:
/// - Cabeçalho escuro com logo, dados da empresa (esq.) e
///   "ORÇAMENTO COMERCIAL" + número (dir.).
/// - Dois boxes lado a lado: Informações do Orçamento e Dados do Cliente.
/// - Seções PRODUTOS / SERVIÇOS com título + linha divisória.
/// - Tabela com headers em caixa alta e fundo cinza claro.
/// - Totais alinhados à direita; VALOR TOTAL com fundo escuro e texto branco.
/// - Observações na mesma página (quando couber).
/// - Rodapé centralizado.
class PdfGenerateExecutiveUseCase {
  final ConvertCoinRepository _moneyConvert;
  final UserRepository _userRepository;

  PdfGenerateExecutiveUseCase(this._moneyConvert, this._userRepository);

  Future<String> executivePDF({
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
      final PdfDocument document = await _buildExecutiveDocument(
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

  Future<Uint8List> executivePDFBytes({
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
      final PdfDocument document = await _buildExecutiveDocument(
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

  // -------------------------------------------------------------------------
  // Documento
  // -------------------------------------------------------------------------

  Future<PdfDocument> _buildExecutiveDocument({
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
    final PdfDocument document = _createDocument();
    final PdfPage page = document.pages.add();

    double currentY = await _drawDarkHeader(page, owner, customer, authToken);
    currentY = _drawInfoBoxesRow(page, customer, currentY + 15);

    PdfPage activePage = page;

    if (countProduct > 0) {
      currentY = _drawSectionHeader(activePage, 'PRODUTOS', currentY + 18);
      final result = _drawItemsTable(
        page: activePage,
        topY: currentY,
        items: items,
        category: 'Produtos',
        countService: countService,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
      activePage = result.page;
      currentY = result.y;
    }

    if (countService > 0) {
      currentY = _drawSectionHeader(activePage, 'SERVIÇOS', currentY + 14);
      final result = _drawItemsTable(
        page: activePage,
        topY: currentY,
        items: items,
        category: 'Serviços',
        countService: countService,
        countProduct: countProduct,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
      activePage = result.page;
      currentY = result.y;
    }

    if (observations.isNotEmpty) {
      currentY = _drawSectionHeader(activePage, 'OBSERVAÇÕES', currentY + 18);
      currentY = _drawObservationsTable(activePage, observations, currentY);
    }

    _drawFooter(activePage, owner);
    return document;
  }

  PdfDocument _createDocument() {
    return PdfDocument()
      ..pageSettings.size = PdfPageSize.a4
      ..pageSettings.margins.left = 30
      ..pageSettings.margins.right = 30
      ..pageSettings.margins.top = 50
      ..pageSettings.margins.bottom = 50;
  }

  // -------------------------------------------------------------------------
  // Cabeçalho escuro
  // -------------------------------------------------------------------------

  Future<double> _drawDarkHeader(
    PdfPage page,
    OwnerPdf owner,
    CustomerInfo customer,
    String? authToken,
  ) async {
    final g = page.graphics;
    final double pageWidth = page.getClientSize().width;
    const double padH = 18;
    const double padV = 14;

    // --- Logo ---
    double logoW = 0;
    double logoH = 0;
    PdfBitmap? image;
    if (owner.fotoId != null && owner.fotoId!.isNotEmpty) {
      try {
        final String fotoId = owner.fotoId ?? '';
        final String endpointUrl = fotoId.startsWith('http')
            ? fotoId
            : 'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=$fotoId';
        final Map<String, String> headers = <String, String>{
          'Accept': 'application/json;odata=verbose',
        };
        if (!kIsWeb) {
          final String token = await _getAuthToken(authToken);
          headers['Authorization'] = 'Bearer $token';
        }
        final response = await http.get(Uri.parse(endpointUrl), headers: headers);
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          image = PdfBitmap(bytes);
          final ratio = image.width / image.height;
          if (image.height == image.width) {
            logoW = 70;
            logoH = 70;
          } else if (image.height > image.width) {
            logoW = 50;
            logoH = 70;
          } else {
            logoW = 70 * ratio;
            logoH = 70;
          }
        }
      } catch (_) {
        if (kIsWeb) {
          // ignora falha de logo no Web
        } else {
          rethrow;
        }
      }
    }

    // --- Altura do conteúdo esquerdo ---
    double leftH = 0;
    if (owner.empresa != null && owner.empresa!.isNotEmpty) leftH += 17;
    final bool hasCnpj = owner.cnpj != null && owner.cnpj!.isNotEmpty;
    final bool hasFone = owner.fone != null && owner.fone!.isNotEmpty;
    if (hasCnpj || hasFone) leftH += 12;
    if (owner.email != null && owner.email!.isNotEmpty) leftH += 12;

    // --- Altura do conteúdo direito ---
    const double rightH = 14 + 22; // título ciano + número grande

    final double contentH = math.max(math.max(logoH, leftH), rightH);
    final double headerH = contentH + padV * 2;

    // --- Fundo escuro (arredondado) ---
    _drawRoundedRect(
      graphics: g,
      brush: PdfSolidBrush(PdfColor(30, 41, 59)),
      rect: Rect.fromLTWH(0, 0, pageWidth, headerH),
      radius: 8,
    );

    // --- Logo ---
    if (image != null) {
      final double yLogo = padV + (contentH - logoH) / 2;
      g.drawImage(image, Rect.fromLTWH(padH, yLogo, logoW, logoH));
    }

    // --- Texto esquerdo ---
    final double textLeft = logoW > 0 ? padH + logoW + 12 : padH;
    double y = padV + (contentH - leftH) / 2;

    final PdfFont whiteBold = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final PdfFont grayReg = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.regular,
    );
    final PdfBrush white = PdfBrushes.white;
    final PdfBrush gray = PdfSolidBrush(PdfColor(180, 190, 200));

    if (owner.empresa != null && owner.empresa!.isNotEmpty) {
      g.drawString(
        owner.empresa!,
        whiteBold,
        brush: white,
        bounds: Rect.fromLTWH(textLeft, y, pageWidth * 0.5, 17),
      );
      y += 17;
    }
    if (hasCnpj || hasFone) {
      final parts = <String>[];
      if (hasCnpj) parts.add('CNPJ: ${owner.cnpj}');
      if (hasFone) parts.add('Tel: ${owner.fone}');
      g.drawString(
        parts.join(' | '),
        grayReg,
        brush: gray,
        bounds: Rect.fromLTWH(textLeft, y, pageWidth * 0.5, 12),
      );
      y += 12;
    }
    if (owner.email != null && owner.email!.isNotEmpty) {
      g.drawString(
        'E-mail: ${owner.email}',
        grayReg,
        brush: gray,
        bounds: Rect.fromLTWH(textLeft, y, pageWidth * 0.5, 12),
      );
      y += 12;
    }

    // --- Texto direito ---
    final double rightX = pageWidth * 0.5;
    double ry = padV + (contentH - rightH) / 2;

    final PdfFont cyanBold = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );
    final PdfBrush cyan = PdfSolidBrush(PdfColor(56, 189, 248));

    g.drawString(
      'ORÇAMENTO COMERCIAL',
      cyanBold,
      brush: cyan,
      bounds: Rect.fromLTWH(rightX, ry, pageWidth * 0.5 - padH, 14),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
    ry += 14;

    final PdfFont bigWhite = PdfStandardFont(
      PdfFontFamily.helvetica,
      18,
      style: PdfFontStyle.bold,
    );
    if (customer.id != null && customer.id!.isNotEmpty) {
      g.drawString(
        '#${customer.id}',
        bigWhite,
        brush: white,
        bounds: Rect.fromLTWH(rightX, ry, pageWidth * 0.5 - padH, 22),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }

    return headerH + 10;
  }

  // -------------------------------------------------------------------------
  // Autenticação
  // -------------------------------------------------------------------------

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
    if (session.EMAIL == null || session.EMAIL!.isEmpty || session.Senha == null || session.Senha!.isEmpty) return '';
    final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: session.EMAIL!.trim(),
      password: session.Senha!.trim(),
    );
    return (await auth.user?.getIdToken()) ?? '';
  }

  // -------------------------------------------------------------------------
  // Boxes lado a lado
  // -------------------------------------------------------------------------

  double _drawInfoBoxesRow(PdfPage page, CustomerInfo customer, double topY) {
    final double pageWidth = page.getClientSize().width;
    const double gap = 12;
    final double boxW = (pageWidth - gap) / 2;

    final h1 = _drawInfoBox(
      page: page,
      title: 'INFORMAÇÕES DO ORÇAMENTO',
      rows: [
        ('Data de Emissão:', customer.data),
        ('Validade:', 'Consultar'),
      ],
      left: 0,
      top: topY,
      width: boxW,
    );

    final h2 = _drawInfoBox(
      page: page,
      title: 'DADOS DO CLIENTE',
      rows: [
        ('Cliente:', customer.customerName),
        ('Telefone:', customer.phone),
        ('Endereço:', customer.street),
        ('Localidade:', _locality(customer)),
      ],
      left: boxW + gap,
      top: topY,
      width: boxW,
    );

    return topY + math.max(h1, h2) + 5;
  }

  String? _locality(CustomerInfo c) {
    final parts = <String>[];
    if (c.neighborhood != null && c.neighborhood!.isNotEmpty) {
      parts.add(c.neighborhood!);
    }
    if (c.city != null && c.city!.isNotEmpty) {
      parts.add(c.city!);
    }
    return parts.isNotEmpty ? parts.join(' - ') : null;
  }

  double _drawInfoBox({
    required PdfPage page,
    required String title,
    required List<(String, String?)> rows,
    required double left,
    required double top,
    required double width,
  }) {
    final grid = PdfGrid()..columns.add(count: 2);

    final headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = title;
    headerRow.cells[0].columnSpan = 2;

    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.bold,
    );
    final PdfFont rowFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.regular,
    );
    final PdfPen borderPen = PdfPen(PdfColor(220, 220, 220), width: 0.5);

    final PdfGridCellStyle titleStyle = PdfGridCellStyle(
      font: titleFont,
      textBrush: PdfSolidBrush(PdfColor(71, 85, 105)),
      backgroundBrush: PdfSolidBrush(PdfColor(248, 250, 252)),
      cellPadding: PdfPaddings(top: 5, bottom: 5, left: 10, right: 10),
    )..borders.all = borderPen;

    grid.headers.applyStyle(titleStyle);

    for (final (label, value) in rows) {
      if (value == null || value.isEmpty) continue;
      final r = grid.rows.add();
      r.cells[0].value = label;
      r.cells[1].value = value;
    }

    final PdfGridCellStyle labelStyle = PdfGridCellStyle(
      font: rowFont,
      textBrush: PdfSolidBrush(PdfColor(100, 100, 100)),
      cellPadding: PdfPaddings(top: 3, bottom: 3, left: 10, right: 4),
    )..borders.all = borderPen;

    final PdfGridCellStyle valueStyle = PdfGridCellStyle(
      font: rowFont,
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 3, bottom: 3, left: 4, right: 10),
    )..borders.all = borderPen;

    for (int i = 0; i < grid.rows.count; i++) {
      grid.rows[i].cells[0].style = labelStyle;
      grid.rows[i].cells[1].style = valueStyle;
    }

    grid.columns[0].width = width * 0.42;
    grid.columns[1].width = width * 0.58;

    final result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(left, top, width, 300),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.onePage,
      ),
    );
    return result?.bounds.height ?? 0;
  }

  // -------------------------------------------------------------------------
  // Título de seção com linha
  // -------------------------------------------------------------------------

  double _drawSectionHeader(PdfPage page, String title, double topY) {
    final g = page.graphics;
    final double w = page.getClientSize().width;
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      11,
      style: PdfFontStyle.bold,
    );
    final size = font.measureString(title);
    const double pad = 8;

    g.drawString(
      title,
      font,
      brush: PdfSolidBrush(PdfColor(30, 41, 59)),
      bounds: Rect.fromLTWH(0, topY, size.width + 2, 16),
    );

    g.drawLine(
      PdfPen(PdfColor(210, 210, 210), width: 0.5),
      Offset(size.width + pad, topY + 8),
      Offset(w, topY + 8),
    );

    return topY + 20;
  }

  // -------------------------------------------------------------------------
  // Tabela de itens
  // -------------------------------------------------------------------------

  _TableResult _drawItemsTable({
    required PdfPage page,
    required double topY,
    required List<ItemsBudget> items,
    required String category,
    required int countService,
    String? totalPriceProducts,
    String? totalPriceServices,
    required String totalPriceBudget,
    int countProduct = 0,
  }) {
    final grid = PdfGrid();
    grid.columns.add(count: 5);

    final header = grid.headers.add(1)[0];
    header.cells[0].value = 'DESCRIÇÃO';
    header.cells[1].value = 'MEDIDA';
    header.cells[2].value = 'QTD';
    header.cells[3].value = 'PREÇO UNIT.';
    header.cells[4].value = 'TOTAL';

    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: headerFont,
      backgroundBrush: PdfSolidBrush(PdfColor(245, 247, 250)),
      textBrush: PdfSolidBrush(PdfColor(71, 85, 105)),
      cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPen(PdfColor(220, 220, 220), width: 0.5)
      ..borders.bottom = PdfPen(PdfColor(220, 220, 220), width: 0.5);

    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 185;
    grid.columns[1].width = 65;
    grid.columns[2].width = 50;
    grid.columns[3].width = 105;
    grid.columns[4].width = 105;

    for (final item in items) {
      if (item.CATEGORIA == category) {
        final row = grid.rows.add();
        row.cells[0].value = item.DESCRICAO ?? '';
        row.cells[1].value = item.MEDIDA ?? '';
        row.cells[2].value = (item.QTD ?? 0).toString();
        row.cells[3].value = _moneyConvert.convertFromDouble(item.PRECO ?? 0);
        row.cells[4].value = _moneyConvert.convertFromDouble(item.TOTAL ?? 0);
      }
    }

    final PdfGridCellStyle rowStyle = PdfGridCellStyle(
      font: PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.regular,
      ),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 4, left: 5, right: 5, bottom: 4),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPen(PdfColor(230, 230, 230), width: 0.5)
      ..borders.bottom = PdfPen(PdfColor(230, 230, 230), width: 0.5);

    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.rows[i].cells.count; j++) {
        grid.rows[i].cells[j].style = rowStyle;
      }
    }

    // Subtotais
    if (category == 'Produtos' && totalPriceProducts != null) {
      _addTotalRow(
        grid: grid,
        label: 'Subtotal Produtos:',
        value: totalPriceProducts,
        style: PdfGridCellStyle(
          font: PdfStandardFont(
            PdfFontFamily.helvetica,
            10,
            style: PdfFontStyle.bold,
          ),
          textBrush: PdfBrushes.black,
          cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
          backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        )
          ..borders.left = PdfPens.transparent
          ..borders.right = PdfPens.transparent
          ..borders.top = PdfPen(PdfColor(200, 200, 200), width: 0.5)
          ..borders.bottom = PdfPen(PdfColor(200, 200, 200), width: 0.5),
        height: 24,
      );
    }
    if (category == 'Serviços' && totalPriceServices != null) {
      _addTotalRow(
        grid: grid,
        label: 'Subtotal Serviços:',
        value: totalPriceServices,
        style: PdfGridCellStyle(
          font: PdfStandardFont(
            PdfFontFamily.helvetica,
            10,
            style: PdfFontStyle.bold,
          ),
          textBrush: PdfBrushes.black,
          cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
          backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        )
          ..borders.left = PdfPens.transparent
          ..borders.right = PdfPens.transparent
          ..borders.top = PdfPen(PdfColor(200, 200, 200), width: 0.5)
          ..borders.bottom = PdfPen(PdfColor(200, 200, 200), width: 0.5),
        height: 24,
      );
    }

    final bool isLast =
        (category == 'Produtos' && countService == 0) || (category == 'Serviços');
    if (isLast) {
      _addTotalRow(
        grid: grid,
        label: 'VALOR TOTAL:',
        value: totalPriceBudget,
        style: PdfGridCellStyle(
          font: PdfStandardFont(
            PdfFontFamily.helvetica,
            12,
            style: PdfFontStyle.bold,
          ),
          textBrush: PdfBrushes.white,
          backgroundBrush: PdfSolidBrush(PdfColor(30, 41, 59)),
          cellPadding: PdfPaddings(top: 6, left: 5, right: 5, bottom: 6),
          format: PdfStringFormat(alignment: PdfTextAlignment.right),
        )
          ..borders.left = PdfPens.transparent
          ..borders.right = PdfPens.transparent
          ..borders.top = PdfPen(PdfColor(30, 41, 59), width: 0.5)
          ..borders.bottom = PdfPen(PdfColor(30, 41, 59), width: 0.5),
        height: 30,
      );
    }

    final result = grid.draw(
      page: page,
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate,
      ),
      bounds: Rect.fromLTWH(
        0,
        topY,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    ) as PdfLayoutResult;

    return _TableResult(result.page ?? page, result.bounds.bottom);
  }

  // -------------------------------------------------------------------------
  // Observações (mesma página)
  // -------------------------------------------------------------------------

  double _drawObservationsTable(
    PdfPage page,
    List<ObservationPdf> observations,
    double topY,
  ) {
    final grid = PdfGrid()..columns.add(count: 2);
    final header = grid.headers.add(1)[0];
    header.cells[0].value = 'DATA';
    header.cells[1].value = 'DESCRIÇÃO DA OBSERVAÇÃO';

    final PdfFont headerFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: headerFont,
      backgroundBrush: PdfSolidBrush(PdfColor(245, 247, 250)),
      textBrush: PdfSolidBrush(PdfColor(71, 85, 105)),
      cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPen(PdfColor(220, 220, 220), width: 0.5)
      ..borders.bottom = PdfPen(PdfColor(220, 220, 220), width: 0.5);

    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 80;
    grid.columns[1].width = page.getClientSize().width - 80;

    for (final obs in observations) {
      final row = grid.rows.add();
      row.cells[0].value = obs.data;
      row.cells[1].value = obs.observacao;
    }

    final PdfGridCellStyle rowStyle = PdfGridCellStyle(
      font: PdfStandardFont(
        PdfFontFamily.helvetica,
        9,
        style: PdfFontStyle.regular,
      ),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 4, left: 5, right: 5, bottom: 4),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPen(PdfColor(230, 230, 230), width: 0.5)
      ..borders.bottom = PdfPen(PdfColor(230, 230, 230), width: 0.5);

    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.rows[i].cells.count; j++) {
        grid.rows[i].cells[j].style = rowStyle;
      }
    }

    final result = grid.draw(
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
    );
    return result?.bounds.bottom ?? topY;
  }

  // -------------------------------------------------------------------------
  // Footer
  // -------------------------------------------------------------------------

  void _drawFooter(PdfPage page, OwnerPdf owner) {
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica,
      8,
      style: PdfFontStyle.regular,
    );
    page.graphics.drawString(
      '${owner.empresa ?? ''} • Gestão de Orçamentos',
      font,
      brush: PdfSolidBrush(PdfColor(150, 150, 150)),
      bounds: Rect.fromLTWH(
        0,
        page.getClientSize().height - 18,
        page.getClientSize().width,
        14,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _addTotalRow({
    required PdfGrid grid,
    required String label,
    required String value,
    required PdfGridCellStyle style,
    required double height,
  }) {
    final PdfGridRow totalRow = grid.rows.add();
    totalRow.cells[3].value = label;
    totalRow.cells[4].value = value;
    for (int i = 0; i < totalRow.cells.count; i++) {
      totalRow.cells[i].style = style;
    }
    totalRow.height = height;
  }

  /// Desenha um retângulo com cantos arredondados.
  void _drawRoundedRect({
    required PdfGraphics graphics,
    required PdfBrush brush,
    required Rect rect,
    required double radius,
  }) {
    final double r = radius;
    final double x = rect.left;
    final double y = rect.top;
    final double w = rect.width;
    final double h = rect.height;

    // Corpo central
    graphics.drawRectangle(
      brush: brush,
      bounds: Rect.fromLTWH(x + r, y, w - r * 2, h),
    );
    graphics.drawRectangle(
      brush: brush,
      bounds: Rect.fromLTWH(x, y + r, w, h - r * 2),
    );

    // 4 cantos arredondados (círculos preenchidos)
    graphics.drawEllipse(
      Rect.fromLTWH(x, y, r * 2, r * 2),
      brush: brush,
    );
    graphics.drawEllipse(
      Rect.fromLTWH(x + w - r * 2, y, r * 2, r * 2),
      brush: brush,
    );
    graphics.drawEllipse(
      Rect.fromLTWH(x + w - r * 2, y + h - r * 2, r * 2, r * 2),
      brush: brush,
    );
    graphics.drawEllipse(
      Rect.fromLTWH(x, y + h - r * 2, r * 2, r * 2),
      brush: brush,
    );
  }

  Future<String> _saveDocument(PdfDocument document, String filename) async {
    final directory = await getTemporaryDirectory();
    final String path = directory.path;
    final File file = File('$path/$filename.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/$filename.pdf';
  }
}
