/// Documento legal (EULA ou Política de Privacidade) exibido no Web.
class LegalDocument {
  final String title;
  final String lastUpdated;
  final String? intro;
  final List<LegalSection> sections;
  final String footer;

  /// Link para o mesmo documento no outro idioma.
  final String switchLanguageLabel;
  final String switchLanguagePath;

  /// Link para o outro documento (Termos ↔ Privacidade) no mesmo idioma.
  final String otherDocumentLabel;
  final String otherDocumentPath;

  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    this.intro,
    required this.sections,
    required this.footer,
    required this.switchLanguageLabel,
    required this.switchLanguagePath,
    required this.otherDocumentLabel,
    required this.otherDocumentPath,
  });
}

class LegalSection {
  final String title;
  final String body;

  const LegalSection(this.title, this.body);
}
