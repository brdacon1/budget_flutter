import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/common/constants/global_uid_budget.dart' as budget;
import 'package:oflite/shared/common/constants/global_uid_user.dart' as uid;
import 'package:oflite/shared/common/constants/global_uid_user.dart' as user_global;
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Geração do PDF do orçamento — Layout **Executivo**.
class PdfGenerateExecutiveUseCase {
  final ConvertCoinRepository _moneyConvert;

  PdfGenerateExecutiveUseCase(this._moneyConvert);

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
      final String localFile = await _saveDocument(document);
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

    double currentY = await _drawLogoWithHeader(
      page, owner, authToken,
    );

    currentY = _drawExecutiveTitle(page, customer, currentY);
    currentY = _drawBudgetInfoSection(page, customer, currentY + 10);
    currentY = _drawClientInfoSection(page, customer, currentY + 10);

    // Produtos
    if (countProduct > 0) {
      currentY = _drawSectionTitle(page, 'PRODUTOS', currentY + 15);
      currentY = _drawItemsTable(
        page: page,
        topY: currentY,
        items: items,
        category: 'Produtos',
        countService: countService,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
    }

    // Serviços
    if (countService > 0) {
      currentY = _drawSectionTitle(page, 'SERVIÇOS', currentY + 10);
      currentY = _drawItemsTable(
        page: page,
        topY: currentY,
        items: items,
        category: 'Serviços',
        countService: countService,
        countProduct: countProduct,
        totalPriceProducts: totalPriceProducts,
        totalPriceServices: totalPriceServices,
        totalPriceBudget: totalPriceBudget,
      );
    }

    _drawFooter(page, owner);

    if (observations.isNotEmpty) {
      _drawObservationsPage(document, observations, owner);
    }

    return document;
  }

  // ---------------------------------------------------------------------------
  // Documento
  // ---------------------------------------------------------------------------

  PdfDocument _createDocument() {
    return PdfDocument()
      ..pageSettings.size = PdfPageSize.a4
      ..pageSettings.margins.left = 30
      ..pageSettings.margins.right = 30
      ..pageSettings.margins.top = 50
      ..pageSettings.margins.bottom = 50;
  }

  // ---------------------------------------------------------------------------
  // Logo + Header da empresa (texto ao lado da imagem)
  // ---------------------------------------------------------------------------

  Future<double> _drawLogoWithHeader(
    PdfPage page,
    OwnerPdf owner,
    String? authToken,
  ) async {
    final PdfGraphics g = page.graphics;
    double logoHeight = 0;
    double logoWidth = 0;
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

        final http.Response response = await http.get(
          Uri.parse(endpointUrl),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final Uint8List fileContent = response.bodyBytes;
          image = PdfBitmap(fileContent);
          final double ratio = image.width / image.height;

          if (image.height == image.width) {
            logoWidth = 80;
            logoHeight = 80;
          } else if (image.height > image.width) {
            logoWidth = 60;
            logoHeight = 80;
          } else {
            logoWidth = 80 * ratio;
            logoHeight = 80;
          }

          g.drawImage(
            image,
            Rect.fromLTWH(0, 0, logoWidth, logoHeight),
          );
        }
      } catch (_) {
        if (kIsWeb) {
          // ignora falha de logo no web
        } else {
          rethrow;
        }
      }
    }

    final double textLeft = logoWidth + 10;

    // Nome empresa (negrito, 12)
    final PdfFont boldFont = PdfStandardFont(
      PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold,
    );
    final PdfFont regularFont = PdfStandardFont(
      PdfFontFamily.helvetica, 9, style: PdfFontStyle.regular,
    );

    double y = 0;
    if (owner.empresa != null && owner.empresa!.isNotEmpty) {
      g.drawString(
        owner.empresa!, boldFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(textLeft, y, page.getClientSize().width - textLeft, 16),
      );
      y += 16;
    }

    // Linha: CNPJ | Tel
    final List<String> details = <String>[];
    if (owner.cnpj != null && owner.cnpj!.isNotEmpty) {
      details.add('CNPJ: ${owner.cnpj}');
    }
    if (owner.fone != null && owner.fone!.isNotEmpty) {
      details.add('Tel: ${owner.fone}');
    }
    if (details.isNotEmpty) {
      g.drawString(
        details.join(' | '), regularFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(textLeft, y, page.getClientSize().width - textLeft, 14),
      );
      y += 13;
    }
    if (owner.email != null && owner.email!.isNotEmpty) {
      g.drawString(
        'E-mail: ${owner.email}', regularFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(textLeft, y, page.getClientSize().width - textLeft, 14),
      );
      y += 13;
    }

    return math.max(logoHeight, y + 5);
  }

  // ---------------------------------------------------------------------------
  // Autenticação
  // ---------------------------------------------------------------------------

  Future<String> _getAuthToken(String? authToken) async {
    if (authToken != null && authToken.isNotEmpty) {
      return authToken;
    }
    if (uid.googleAuth!) {
      return (await FirebaseAuth.instance.currentUser?.getIdToken()) ?? '';
    }
    final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: user_global.email!.trim(),
      password: user_global.password!.trim(),
    );
    return (await auth.user?.getIdToken()) ?? '';
  }

  // ---------------------------------------------------------------------------
  // Título "ORÇAMENTO COMERCIAL"
  // ---------------------------------------------------------------------------

  double _drawExecutiveTitle(
    PdfPage page,
    CustomerInfo customer,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;
    final PdfFont bigFont = PdfStandardFont(
      PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold,
    );
    final PdfFont numFont = PdfStandardFont(
      PdfFontFamily.helvetica, 11, style: PdfFontStyle.regular,
    );

    g.drawString(
      'ORÇAMENTO COMERCIAL',
      bigFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, topY, page.getClientSize().width, 26),
    );

    if (customer.id != null && customer.id!.isNotEmpty) {
      g.drawString(
        '#${customer.id}',
        numFont,
        brush: PdfBrushes.black,
        bounds: Rect.fromLTWH(0, topY + 24, page.getClientSize().width, 18),
      );
    }
    return topY + 46;
  }

  // ---------------------------------------------------------------------------
  // "INFORMAÇÕES DO ORÇAMENTO"
  // ---------------------------------------------------------------------------

  double _drawBudgetInfoSection(
    PdfPage page,
    CustomerInfo customer,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;
    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold,
    );
    final PdfFont rowFont = PdfStandardFont(
      PdfFontFamily.helvetica, 9, style: PdfFontStyle.regular,
    );

    g.drawString(
      'INFORMAÇÕES DO ORÇAMENTO',
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, topY, page.getClientSize().width, 18),
    );

    final PdfGrid grid = PdfGrid()..columns.add(count: 2);
    grid.headers.clear();

    final PdfGridCellStyle style = PdfGridCellStyle(
      font: rowFont,
      cellPadding: PdfPaddings(top: 2, bottom: 2, left: 0, right: 2),
    )..borders.all = PdfPens.transparent;

    void addRow(String label, String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = label;
      row.cells[1].value = value;
    }

    addRow('Data de Emissão:', customer.data);
    addRow('Validade:', 'Consultar');

    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.rows[i].cells.count; j++) {
        grid.rows[i].cells[j].style = style;
      }
    }
    grid.columns[0].width = 120;
    grid.columns[1].width = page.getClientSize().width - 120;

    final PdfLayoutResult? result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0, topY + 18,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.onePage,
      ),
    );
    return result != null ? result.bounds.bottom : topY + 18;
  }

  // ---------------------------------------------------------------------------
  // "DADOS DO CLIENTE"
  // ---------------------------------------------------------------------------

  double _drawClientInfoSection(
    PdfPage page,
    CustomerInfo customer,
    double topY,
  ) {
    final PdfGraphics g = page.graphics;
    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica, 11, style: PdfFontStyle.bold,
    );
    final PdfFont rowFont = PdfStandardFont(
      PdfFontFamily.helvetica, 9, style: PdfFontStyle.regular,
    );

    g.drawString(
      'DADOS DO CLIENTE',
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, topY, page.getClientSize().width, 18),
    );

    final PdfGrid grid = PdfGrid()..columns.add(count: 2);
    grid.headers.clear();

    final PdfGridCellStyle style = PdfGridCellStyle(
      font: rowFont,
      cellPadding: PdfPaddings(top: 2, bottom: 2, left: 0, right: 2),
    )..borders.all = PdfPens.transparent;

    void addRow(String label, String? value) {
      if (value == null || value.isEmpty) return;
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = label;
      row.cells[1].value = value;
    }

    addRow('Cliente:', customer.customerName);
    addRow('Telefone:', customer.phone);
    addRow('Endereço:', customer.street);

    final locality = <String>[];
    if (customer.neighborhood != null && customer.neighborhood!.isNotEmpty) {
      locality.add(customer.neighborhood!);
    }
    if (customer.city != null && customer.city!.isNotEmpty) {
      locality.add(customer.city!);
    }
    if (locality.isNotEmpty) {
      addRow('Localidade:', locality.join(' - '));
    }

    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.rows[i].cells.count; j++) {
        grid.rows[i].cells[j].style = style;
      }
    }
    grid.columns[0].width = 120;
    grid.columns[1].width = page.getClientSize().width - 120;

    final PdfLayoutResult? result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0, topY + 18,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.onePage,
      ),
    );
    return result != null ? result.bounds.bottom : topY + 18;
  }

  // ---------------------------------------------------------------------------
  // Título de seção (PRODUTOS / SERVIÇOS)
  // ---------------------------------------------------------------------------

  double _drawSectionTitle(PdfPage page, String title, double topY) {
    final PdfGraphics g = page.graphics;
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold,
    );
    g.drawString(
      title,
      font,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, topY, page.getClientSize().width, 20),
    );
    return topY + 20;
  }

  // ---------------------------------------------------------------------------
  // Tabela de itens (produtos ou serviços)
  // ---------------------------------------------------------------------------

  double _drawItemsTable({
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
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 5);

    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'DESCRIÇÃO';
    header.cells[1].value = 'MEDIDA';
    header.cells[2].value = 'QTD';
    header.cells[3].value = 'PREÇO UNIT.';
    header.cells[4].value = 'TOTAL';

    final PdfFont fontHeader = PdfStandardFont(
      PdfFontFamily.helvetica, 9, style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: fontHeader,
      backgroundBrush: PdfSolidBrush(PdfColor(240, 240, 240)),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 4, left: 4, right: 4, bottom: 4),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;

    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 190;
    grid.columns[1].width = 65;
    grid.columns[2].width = 50;
    grid.columns[3].width = 100;
    grid.columns[4].width = 100;

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

    // Totais
    if (category == 'Produtos' && totalPriceProducts != null) {
      _addTotalRow(
        grid: grid,
        label: 'Subtotal Produtos:',
        value: totalPriceProducts,
        style: _totalRowStyle(fontHeader),
        height: 22,
      );
    }
    if (category == 'Serviços' && totalPriceServices != null) {
      _addTotalRow(
        grid: grid,
        label: 'Subtotal Serviços:',
        value: totalPriceServices,
        style: _totalRowStyle(fontHeader),
        height: 22,
      );
    }

    // Se serviços=0 e estamos em produtos, ou vice-versa: total geral aqui
    final bool isLastTable =
        (category == 'Produtos' && countService == 0) ||
        (category == 'Serviços');

    if (isLastTable) {
      _addTotalRow(
        grid: grid,
        label: 'VALOR TOTAL:',
        value: totalPriceBudget,
        style: _budgetTotalRowStyle(),
        height: 28,
      );
    }

    final PdfLayoutResult result = grid.draw(
      page: page,
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate,
      ),
      bounds: Rect.fromLTWH(
        0, topY,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    ) as PdfLayoutResult;

    return result.bounds.bottom;
  }

  // ---------------------------------------------------------------------------
  // Observações (nova página)
  // ---------------------------------------------------------------------------

  void _drawObservationsPage(
    PdfDocument document,
    List<ObservationPdf> observations,
    OwnerPdf owner,
  ) {
    final PdfPage page = document.pages.add();
    final PdfGraphics g = page.graphics;

    final PdfFont titleFont = PdfStandardFont(
      PdfFontFamily.helvetica, 13, style: PdfFontStyle.bold,
    );
    g.drawString(
      'OBSERVAÇÕES',
      titleFont,
      brush: PdfBrushes.black,
      bounds: Rect.fromLTWH(0, 10, page.getClientSize().width, 24),
    );

    final PdfGrid grid = PdfGrid()..columns.add(count: 2);
    final PdfGridRow header = grid.headers.add(1)[0];
    header.cells[0].value = 'DATA';
    header.cells[1].value = 'DESCRIÇÃO DA OBSERVAÇÃO';

    final PdfFont fontHeader = PdfStandardFont(
      PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold,
    );
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: fontHeader,
      backgroundBrush: PdfSolidBrush(PdfColor(240, 240, 240)),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 4, left: 4, right: 4, bottom: 4),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;

    grid.headers.applyStyle(headerStyle);
    grid.columns[0].width = 80;
    grid.columns[1].width = page.getClientSize().width - 80;

    for (final obs in observations) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = obs.data;
      row.cells[1].value = obs.observacao;
    }

    _applyRowStyle(grid, _itemRowStyle());

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0, 40,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
      format: PdfLayoutFormat(
        breakType: PdfLayoutBreakType.fitPage,
        layoutType: PdfLayoutType.paginate,
      ),
    );

    // Footer na página de observações
    final PdfFont footerFont = PdfStandardFont(
      PdfFontFamily.helvetica, 8, style: PdfFontStyle.regular,
    );
    g.drawString(
      '${owner.empresa ?? ''} • Gestão de Orçamentos',
      footerFont,
      brush: PdfBrushes.gray,
      bounds: Rect.fromLTWH(
        0, page.getClientSize().height - 20,
        page.getClientSize().width, 16,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  void _drawFooter(PdfPage page, OwnerPdf owner) {
    final PdfFont font = PdfStandardFont(
      PdfFontFamily.helvetica, 8, style: PdfFontStyle.regular,
    );
    page.graphics.drawString(
      '${owner.empresa ?? ''} • Gestão de Orçamentos',
      font,
      brush: PdfBrushes.gray,
      bounds: Rect.fromLTWH(
        0, page.getClientSize().height - 20,
        page.getClientSize().width, 16,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PdfGridCellStyle _itemRowStyle() {
    return PdfGridCellStyle()
      ..cellPadding = PdfPaddings(top: 4, left: 4, right: 4, bottom: 4)
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;
  }

  PdfGridCellStyle _totalRowStyle(PdfFont font) {
    return PdfGridCellStyle(
      font: font,
      cellPadding: PdfPaddings(top: 4, left: 4, right: 4, bottom: 4),
      textBrush: PdfBrushes.black,
      backgroundBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.lightGray;
  }

  PdfGridCellStyle _budgetTotalRowStyle() {
    return PdfGridCellStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      textBrush: PdfBrushes.black,
      cellPadding: PdfPaddings(top: 4, left: 4, right: 4, bottom: 4),
      backgroundBrush: PdfSolidBrush(PdfColor(240, 240, 240)),
    )
      ..borders.left = PdfPens.transparent
      ..borders.right = PdfPens.transparent
      ..borders.top = PdfPens.lightGray
      ..borders.bottom = PdfPens.transparent;
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
  }

  void _applyRowStyle(PdfGrid grid, PdfGridCellStyle style) {
    for (int i = 0; i < grid.rows.count; i++) {
      final PdfGridRow row = grid.rows[i];
      for (int j = 0; j < row.cells.count; j++) {
        row.cells[j].style = style;
      }
    }
  }

  Future<String> _saveDocument(PdfDocument document) async {
    final directory = await getTemporaryDirectory();
    final String path = directory.path;
    final File file = File('$path/${budget.IDORCAMENTO}.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return '$path/${budget.IDORCAMENTO}.pdf';
  }
}
