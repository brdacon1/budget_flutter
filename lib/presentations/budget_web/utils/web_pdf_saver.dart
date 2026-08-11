// Barrel com import condicional: usa a impl. Web (dart:html) no Flutter Web
// e o stub no mobile/desktop, evitando que `dart:html` quebre o build mobile.
export 'web_pdf_saver_io.dart' if (dart.library.html) 'web_pdf_saver_web.dart';
