import 'package:flutter/widgets.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/document_validation_result.dart';

/// Textos do módulo Pdf internacionalizados.
class PdfStrings {
  const PdfStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Presenter / Views ---
  static String get pdfTitle => _isPt ? 'PDF' : 'PDF';

  static String get sharePdf => _isPt ? 'Compartilhar PDF' : 'Share PDF';

  static String get shareButton => _isPt ? 'COMPARTILHAR' : 'SHARE';

  static String get pdfBudgetErrorMessage =>
      _isPt
          ? "Para visualizar o PDF do orçamento é necessário incluir apenas um produto ou serviço na aba 'Itens'"
          : "To view the budget PDF you must include at least one product or service in the 'Items' tab";

  static String get errorTitle => _isPt ? 'Erro' : 'Error';

  static String get editPdfTitle => _isPt ? 'Editar PDF' : 'Edit PDF';

  static String get pdfInfoTitle =>
      _isPt ? 'Informações do PDF' : 'PDF information';

  static String get noImage =>
      _isPt ? 'Sem imagem disponível' : 'No image available';

  static String get tapToAddImage =>
      _isPt ? 'Toque para incluir nova imagem' : 'Tap to add new image';

  static String get errorLoadImage =>
      _isPt ? 'Erro ao carregar a imagem' : 'Error loading image';

  static String get updateButton => _isPt ? 'Atualizar' : 'Update';

  static String get errorUpdatePdf =>
      _isPt
          ? 'Problemas ao atualizar os dados do PDF'
          : 'Problems updating PDF data';

  static String get editLogoTitle => _isPt ? 'Editar Logo' : 'Edit Logo';

  // --- PDF Edit ---
  static String get addressInfo =>
      _isPt ? 'Informações de endereço' : 'Address information';

  static String get enterpriseInfo =>
      _isPt ? 'Informações da empresa' : 'Company information';

  static String get clickToEdit =>
      _isPt ? 'Clique para editar' : 'Click to edit';

  static String get cepHint => _isPt ? 'CEP' : 'ZIP';

  static String get streetHint => _isPt ? 'Rua' : 'Street';

  static String get cityHint => _isPt ? 'Cidade' : 'City';

  static String get neighborhoodHint => _isPt ? 'Bairro' : 'Neighborhood';

  static String get companyNameHint =>
      _isPt ? 'Nome da empresa' : 'Company name';

  static String get phoneHint => _isPt ? 'Telefone' : 'Phone';

  static String get cnpjHint => _isPt ? 'CNPJ / CPF' : 'Tax ID (CNPJ / CPF)';

  static String documentError(DocumentValidationError error) {
    switch (error) {
      case DocumentValidationError.empty:
        return _isPt
            ? 'O campo CPF ou CNPJ é obrigatório.'
            : 'CPF or CNPJ is required.';
      case DocumentValidationError.invalidCpf:
        return _isPt ? 'CPF inválido.' : 'Invalid CPF.';
      case DocumentValidationError.invalidCnpj:
        return _isPt ? 'CNPJ inválido.' : 'Invalid CNPJ.';
      case DocumentValidationError.invalidLength:
        return _isPt
            ? 'Digite um CPF ou CNPJ válido.'
            : 'Enter a valid CPF or CNPJ.';
    }
  }

  // --- UseCase PDF ---
  static String get itemListTitle =>
      _isPt ? 'LISTA DE ITENS DO ORÇAMENTO' : 'BUDGET ITEM LIST';

  static String get productDescription =>
      _isPt ? 'Descrição dos produtos' : 'Product description';

  static String get serviceDescription =>
      _isPt ? 'Descrição dos serviços' : 'Service description';

  static String get measure => _isPt ? 'Medida' : 'Measure';

  static String get quantity => _isPt ? 'Qtd' : 'Qty';

  static String get price => _isPt ? 'Preço' : 'Price';

  static String get total => _isPt ? 'Total' : 'Total';

  static String get observationsTitle =>
      _isPt ? 'OBSERVAÇÕES DO ORÇAMENTO' : 'BUDGET OBSERVATIONS';

  static String get date => _isPt ? 'Data' : 'Date';

  static String get observation => _isPt ? 'Observação' : 'Observation';

  static String get paymentsMade =>
      _isPt ? 'PAGAMENTOS REALIZADOS' : 'PAYMENTS MADE';

  static String get paymentDescription =>
      _isPt ? 'Descrição dos pagamentos' : 'Payment description';

  static String get paymentMethod =>
      _isPt ? 'Metodo de pagamento' : 'Payment method';

  static String get amountPaid => _isPt ? 'Valor pago' : 'Amount paid';

  static String get notPossibleGeneratePdf =>
      _isPt ? 'Não foi possível gerar o PDF' : 'Could not generate the PDF';

  static String get oops => _isPt ? 'Ops!' : 'Oops!';
}
