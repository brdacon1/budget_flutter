import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:oflite/Services/convert_coin.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as uid;
import 'package:oflite/models/global_uid_user.dart' as user_global;
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';
import 'package:oflite/models/owner_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../services/http_request.dart';

/// Geração do PDF do orçamento (dados do titular, dados do orçamento,
/// tabela de produtos, tabela de serviços e observações).
class PdfGenerateUseCase {
  final HttpRequest _db = HttpRequest();
  final ConvertCoin _moneyConvert = ConvertCoin();

  Future<String> patternPDF({
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
      final String localFile = await _saveDocument(document);
      items.clear();
      observations.clear();
      document.dispose();
      return localFile;
    } catch (_) {
      rethrow;
    }
  }

  /// Versão Web do [patternPDF]: retorna os bytes do PDF em memória em vez de
  /// gravar num arquivo (no navegador `dart:io` File não funciona). Reaproveita
  /// **exatamente** o mesmo desenho/regra de negócio do PDF — apenas a
  /// persistência final muda. O [authToken] opcional, quando fornecido, é
  /// usado para baixar o logo do Storage em vez de reautenticar o usuário
  /// (no Web não há login do dono).
  Future<Uint8List> patternPDFBytes({
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

  /// Constrói e popula o [PdfDocument] com todo o conteúdo do orçamento.
  /// Extraído de [patternPDF] para ser reaproveitado pela versão Web
  /// ([patternPDFBytes]) sem duplicar a regra de negócio do desenho.
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
    final PdfDocument document = _createDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final double sizeWithImage = await _drawLogo(page, owner, authToken);

    _drawOwnerGrid(page, graphics, owner, sizeWithImage);
    _drawBudgetDataTitle(page, graphics);
    final double budgetDataBottomY = _drawBudgetDataGrid(page, customer);

    // Posicionamento dinâmico: o título da lista de itens fica logo abaixo
    // dos dados do orçamento, respeitando a altura real renderizada.
    final double itemsTitleY = budgetDataBottomY + 10;
    _drawItemsSectionTitle(page, graphics, itemsTitleY);
    final double itemsTableY = itemsTitleY + 40;
    final double resultTableProductHeight = _drawProductTable(
      page: page,
      topY: itemsTableY,
      countProduct: countProduct,
      countService: countService,
      totalPriceProducts: totalPriceProducts,
      totalPriceBudget: totalPriceBudget,
      items: items,
    );
    _drawServiceTable(
      page: page,
      topY: itemsTableY + resultTableProductHeight,
      countService: countService,
      totalPriceServices: totalPriceServices,
      totalPriceBudget: totalPriceBudget,
      items: items,
    );

    if (observations.isNotEmpty) {
      _drawObservationsTable(document, observations);
    }
    return document;
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

  Future<double> _drawLogo(PdfPage page, OwnerPdf owner, String? authToken) async {
    if (owner.fotoId == null || owner.fotoId!.isEmpty) {
      return 0;
    }

    try {
      final String token = await _getAuthToken(authToken);

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

  Future<String> _getAuthToken(String? authToken) async {
    // Web: o token provisório do Firebase chega pela URL — não há login do
    // dono no navegador. Reutiliza-o direto.
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }
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

  void _drawOwnerGrid(
    PdfPage page,
    PdfGraphics graphics,
    OwnerPdf owner,
    double sizeWithImage,
  ) {
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
  // Budget data section title
  // ---------------------------------------------------------------------------

  void _drawBudgetDataTitle(PdfPage page, PdfGraphics graphics) {
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
      '\nDADOS DO ORÇAMENTO',
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
    const double startY = 135;

    // Fonte/padding explícitos nas células => altura de linha previsível e
    // texto sempre visível (não depende da fonte padrão do PdfGrid).
    final PdfFont rowFont = PdfStandardFont(
      PdfFontFamily.helvetica,
      9,
      style: PdfFontStyle.regular,
    );
    final PdfGridCellStyle style = PdfGridCellStyle(
      font: rowFont,
      cellPadding: PdfPaddings(top: 2, bottom: 2, left: 0, right: 2),
    )..borders.all = PdfPens.transparent;

    // Coluna esquerda: dados do orçamento e do cliente.
    final PdfGrid leftGrid = PdfGrid()..columns.add(count: 2);
    leftGrid.headers.clear();

    void addLeftRow(String label, String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = leftGrid.rows.add();
      row.cells[0].value = label;
      row.cells[1].value = value;
    }

    addLeftRow('Número :', customer.id);
    addLeftRow('Criado em :', customer.data);
    addLeftRow('Cliente :', customer.customerName);
    addLeftRow('Telefone :', customer.phone);
    addLeftRow('Empresa :', customer.companyName);

    // Coluna direita: apenas o endereço do cliente (apenas os preenchidos
    // aparecem, dinamicamente).
    final PdfGrid rightGrid = PdfGrid()..columns.add(count: 2);
    rightGrid.headers.clear();

    void addRightRow(String label, String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = rightGrid.rows.add();
      row.cells[0].value = label;
      row.cells[1].value = value;
    }

    addRightRow('Rua :', customer.street);
    addRightRow('Bairro :', customer.neighborhood);
    addRightRow('Cidade :', customer.city);
    addRightRow('CEP :', customer.zip);

    for (final PdfGrid grid in <PdfGrid>[leftGrid, rightGrid]) {
      for (int i = 0; i < grid.rows.count; i++) {
        final PdfGridRow row = grid.rows[i];
        for (int j = 0; j < row.cells.count; j++) {
          row.cells[j].style = style;
        }
      }
    }

    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: rowFont,
      textBrush: PdfBrushes.black,
      textPen: PdfPens.white,
    );
    leftGrid.headers.applyStyle(headerStyle);
    rightGrid.headers.applyStyle(headerStyle);

    final double pageWidth = page.getClientSize().width;
    final double halfWidth = pageWidth / 2;
    leftGrid.columns[0].width = 70;
    leftGrid.columns[1].width = halfWidth - 70;
    rightGrid.columns[0].width = 70;
    rightGrid.columns[1].width = halfWidth - 70;

    // Layout em uma única página: o overload `page:` devolve um
    // PdfLayoutResult cujo `bounds` é a área REAL consumida pelo grid (ao
    // contrário do overload `graphics:`, que devolve a altura total passada).
    // Usar a base real evita que o título da lista de itens seja desenhado
    // por cima das últimas linhas dos dados do cliente.
    final PdfLayoutFormat onePageFormat = PdfLayoutFormat(
      breakType: PdfLayoutBreakType.fitPage,
      layoutType: PdfLayoutType.onePage,
    );

    double bottomY = startY;

    if (leftGrid.rows.count > 0) {
      final PdfLayoutResult? result = leftGrid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, startY, halfWidth, page.getClientSize().height),
        format: onePageFormat,
      );
      if (result != null && result.bounds.bottom > bottomY) {
        bottomY = result.bounds.bottom;
      }
    }

    if (rightGrid.rows.count > 0) {
      final PdfLayoutResult? result = rightGrid.draw(
        page: page,
        bounds: Rect.fromLTWH(
          halfWidth,
          startY,
          halfWidth,
          page.getClientSize().height,
        ),
        format: onePageFormat,
      );
      if (result != null && result.bounds.bottom > bottomY) {
        bottomY = result.bounds.bottom;
      }
    }

    return bottomY;
  }

  // ---------------------------------------------------------------------------
  // Section titles
  // ---------------------------------------------------------------------------

  void _drawItemsSectionTitle(PdfPage page, PdfGraphics graphics, double topY) {
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
      bounds: Rect.fromLTWH(0, topY, page.getClientSize().width, 30),
    );

    graphics.drawString(
      'LISTA DE ITENS DO ORÇAMENTO',
      font1,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(
        0,
        topY + 7,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: format,
    );
  }

  // ---------------------------------------------------------------------------
  // Items tables
  // ---------------------------------------------------------------------------

  double _drawProductTable({
    required PdfPage page,
    required double topY,
    required int countProduct,
    required int countService,
    required String totalPriceProducts,
    required String totalPriceBudget,
    required List<ItemsBudget> items,
  }) {
    if (countProduct <= 0) {
      return 0;
    }

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);

    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'Descrição dos produtos';
    header.cells[1].value = 'Medida';
    header.cells[2].value = 'Qtd';
    header.cells[3].value = 'Preço';
    header.cells[4].value = 'Total';

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
    grid.columns[1].width = 75;
    grid.columns[3].width = 105;
    grid.columns[4].width = 105;

    for (final item in items) {
      if (item.CATEGORIA == 'Produtos') {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = item.DESCRICAO!;
        row.cells[1].value = item.MEDIDA!;
        row.cells[2].value = item.QTD.toString();
        row.cells[3].value = _moneyConvert.convertFromDouble(item.PRECO!);
        row.cells[4].value = _moneyConvert.convertFromDouble(item.TOTAL!);
      }
    }

    _applyRowStyle(grid, _createItemRowStyle());

    _addTotalRow(
      grid: grid,
      label: 'Valor de produtos:',
      value: totalPriceProducts,
      style: _createTotalRowStyle(fontHeader),
      height: 25,
    );

    if (countService <= 0) {
      _addTotalRow(
        grid: grid,
        label: 'Valor total:',
        value: totalPriceBudget,
        style: _createBudgetTotalRowStyle(),
        height: 30,
      );
    }

    final PdfLayoutResult result = grid.draw(
      page: page,
      format: _paginateLayoutFormat(),
      bounds: Rect.fromLTWH(
        0,
        topY,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    ) as PdfLayoutResult;

    return result.bounds.height;
  }

  void _drawServiceTable({
    required PdfPage page,
    required double topY,
    required int countService,
    required String totalPriceServices,
    required String totalPriceBudget,
    required List<ItemsBudget> items,
  }) {
    if (countService <= 0) {
      return;
    }

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);

    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'Descrição dos serviços';
    header.cells[1].value = 'Medida';
    header.cells[2].value = 'Qtd';
    header.cells[3].value = 'Preço';
    header.cells[4].value = 'Total';

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
    grid.columns[1].width = 75;
    grid.columns[3].width = 105;
    grid.columns[4].width = 105;

    for (final item in items) {
      if (item.CATEGORIA == 'Serviços') {
        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = item.DESCRICAO!;
        row.cells[1].value = item.MEDIDA!;
        row.cells[2].value = item.QTD.toString();
        row.cells[3].value = _moneyConvert.convertFromDouble(item.PRECO!);
        row.cells[4].value = _moneyConvert.convertFromDouble(item.TOTAL!);
      }
    }

    _applyRowStyle(grid, _createItemRowStyle());

    _addTotalRow(
      grid: grid,
      label: 'Valor de serviços:',
      value: totalPriceServices,
      style: _createTotalRowStyle(fontHeader),
      height: 25,
    );

    _addTotalRow(
      grid: grid,
      label: 'Valor total:',
      value: totalPriceBudget,
      style: _createBudgetTotalRowStyle(),
      height: 30,
    );

    grid.draw(
      page: page,
      format: _paginateLayoutFormat(),
      bounds: Rect.fromLTWH(
        0,
        topY,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Observations table
  // ---------------------------------------------------------------------------

  void _drawObservationsTable(
    PdfDocument document,
    List<ObservationPdf> observations,
  ) {
    final PdfPage pageComment = document.pages.add();
    final PdfGraphics graphicsComment = pageComment.graphics;

    final PdfFont font1 = PdfStandardFont(
      PdfFontFamily.helvetica,
      13,
      style: PdfFontStyle.bold,
    );
    final PdfStringFormat format = PdfStringFormat(
      textDirection: PdfTextDirection.rightToLeft,
      alignment: PdfTextAlignment.center,
    );

    graphicsComment.drawRectangle(
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      pen: PdfPen(PdfColor(211, 211, 211)),
      bounds: Rect.fromLTWH(0, 0, pageComment.getClientSize().width, 30),
    );

    graphicsComment.drawString(
      'OBSERVAÇÕES DO ORÇAMENTO',
      font1,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(
        0,
        8.5,
        pageComment.getClientSize().width,
        pageComment.getClientSize().height,
      ),
      format: format,
    );

    final PdfGrid commentPdfGrid = PdfGrid()..columns.add(count: 5);
    final PdfGridRow headerComment = commentPdfGrid.headers.add(1)[0];
    headerComment.cells[0].value = 'Data';
    headerComment.cells[1].value = 'Observação';

    final PdfStringFormat formatComment = PdfStringFormat(
      textDirection: PdfTextDirection.leftToRight,
      alignment: PdfTextAlignment.center,
    );
    final PdfFont fontHeaderComment = PdfStandardFont(
      PdfFontFamily.helvetica,
      10,
      style: PdfFontStyle.bold,
    );

    final PdfGridCellStyle headerStyleComment = PdfGridCellStyle(
      font: fontHeaderComment,
      format: formatComment,
      backgroundBrush: PdfSolidBrush(PdfColor(245, 245, 245)),
      textBrush: PdfBrushes.black,
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;

    commentPdfGrid.headers.applyStyle(headerStyleComment);
    commentPdfGrid.columns[0].width = 75;
    commentPdfGrid.columns[1].width = 460;

    for (final obs in observations) {
      final PdfGridRow row = commentPdfGrid.rows.add();
      row.cells[0].value = obs.data;
      row.cells[1].value = obs.observacao;
    }

    final PdfGridCellStyle styleComment = PdfGridCellStyle()
      ..cellPadding = PdfPaddings(top: 5, left: 15, right: 5, bottom: 5)
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;

    _applyRowStyle(commentPdfGrid, styleComment);

    final PdfLayoutFormat layoutFormatComment = PdfLayoutFormat()
      ..breakType = PdfLayoutBreakType.fitPage
      ..layoutType = PdfLayoutType.paginate;

    commentPdfGrid.draw(
      page: pageComment,
      bounds: Rect.fromLTWH(
        0,
        50,
        pageComment.getClientSize().width,
        pageComment.getClientSize().height,
      ),
      format: layoutFormatComment,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PdfGridCellStyle _createItemRowStyle() {
    final PdfGridCellStyle style = PdfGridCellStyle()
      ..cellPadding = PdfPaddings(top: 5, left: 5, right: 5, bottom: 5)
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;
    return style;
  }

  PdfGridCellStyle _createTotalRowStyle(PdfFont fontHeader) {
    final PdfGridCellStyle style = PdfGridCellStyle(
      font: fontHeader,
      cellPadding: PdfPaddings(top: 5, left: 5, right: 5, bottom: 5),
      textBrush: PdfBrushes.black,
      backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;
    return style;
  }

  PdfGridCellStyle _createBudgetTotalRowStyle() {
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
    final directory = await getTemporaryDirectory();
    print(directory);
    final String path = directory.path;
    final File file = File('$path/${budget.IDORCAMENTO}.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/${budget.IDORCAMENTO}.pdf';
  }
}
