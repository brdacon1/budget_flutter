import 'dart:ui';

/// Conversão pura: tamanho da logo encaixada em [maxW] x [maxH] mantendo a
/// proporção original (nunca estica nem achata a imagem).
Size fitLogoSize(num imageW, num imageH, {double maxW = 80, double maxH = 80}) {
  if (imageW <= 0 || imageH <= 0) return Size.zero;
  final double ratio = imageW / imageH;
  double h = maxH;
  double w = h * ratio;
  if (w > maxW) {
    w = maxW;
    h = w / ratio;
  }
  return Size(w, h);
}
