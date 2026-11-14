import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Equivalente a `GoogleFonts.poppinsTextTheme`, mas retornando o `TextTheme`
/// de `package:flutter/material.dart`.
///
/// A partir do google_fonts 9.0.0 o pacote usa o `TextTheme` do pacote
/// `material_ui`, que é um tipo diferente do `TextTheme` do Flutter SDK
/// (usado por `ThemeData`). Como `TextStyle` é compartilhado entre os dois,
/// aplicamos `GoogleFonts.poppins` estilo a estilo, exatamente como o pacote
/// faz internamente.
TextTheme poppinsTextTheme([TextTheme? textTheme]) {
  textTheme ??= ThemeData.light().textTheme;
  return TextTheme(
    displayLarge: GoogleFonts.poppins(textStyle: textTheme.displayLarge),
    displayMedium: GoogleFonts.poppins(textStyle: textTheme.displayMedium),
    displaySmall: GoogleFonts.poppins(textStyle: textTheme.displaySmall),
    headlineLarge: GoogleFonts.poppins(textStyle: textTheme.headlineLarge),
    headlineMedium: GoogleFonts.poppins(textStyle: textTheme.headlineMedium),
    headlineSmall: GoogleFonts.poppins(textStyle: textTheme.headlineSmall),
    titleLarge: GoogleFonts.poppins(textStyle: textTheme.titleLarge),
    titleMedium: GoogleFonts.poppins(textStyle: textTheme.titleMedium),
    titleSmall: GoogleFonts.poppins(textStyle: textTheme.titleSmall),
    bodyLarge: GoogleFonts.poppins(textStyle: textTheme.bodyLarge),
    bodyMedium: GoogleFonts.poppins(textStyle: textTheme.bodyMedium),
    bodySmall: GoogleFonts.poppins(textStyle: textTheme.bodySmall),
    labelLarge: GoogleFonts.poppins(textStyle: textTheme.labelLarge),
    labelMedium: GoogleFonts.poppins(textStyle: textTheme.labelMedium),
    labelSmall: GoogleFonts.poppins(textStyle: textTheme.labelSmall),
  );
}
