import 'dart:typed_data';

/// Stub para plataformas não-Web (mobile/desktop). A função nunca é chamada
/// no fluxo mobile — apenas o Web do orçamento a invoca. Lança para deixar
/// claro se algum código a chamar acidentalmente fora do Web.
void savePdfBytesWeb(Uint8List bytes, String fileName) {
  throw UnsupportedError('savePdfBytesWeb só é suportado no Flutter Web.');
}
