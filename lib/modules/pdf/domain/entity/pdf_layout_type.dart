/// Tipos de layout disponíveis para geração do PDF do orçamento.
enum PdfLayoutType {
  standard,
  executive,
  professional,
}

extension PdfLayoutTypeExtension on PdfLayoutType {
  String get displayName {
    switch (this) {
      case PdfLayoutType.standard:
        return 'Padrão';
      case PdfLayoutType.executive:
        return 'Executivo';
      case PdfLayoutType.professional:
        return 'Profissional';
    }
  }
}
