import 'document_validation_result.dart';

/// Conversão pura: aplica a máscara de CPF ou CNPJ a um documento já limpo.
class FormatDocumentUsecase {
  const FormatDocumentUsecase();

  String call(String cleaned, DocumentType type) {
    final c = cleaned.toUpperCase();
    switch (type) {
      case DocumentType.cpf:
        return '${c.substring(0, 3)}.${c.substring(3, 6)}.${c.substring(6, 9)}-${c.substring(9, 11)}';
      case DocumentType.cnpj:
        return '${c.substring(0, 2)}.${c.substring(2, 5)}.${c.substring(5, 8)}/${c.substring(8, 12)}-${c.substring(12, 14)}';
    }
  }

  /// Formata enquanto o usuário digita (parcial), escolhendo CPF até 11
  /// caracteres e CNPJ acima disso.
  String partial(String raw) {
    final c = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final limited = c.length > 14 ? c.substring(0, 14) : c;
    final isCpf = limited.length <= 11 && RegExp(r'^\d*$').hasMatch(limited);
    final seps =
        isCpf
            ? const {3: '.', 6: '.', 9: '-'}
            : const {2: '.', 5: '.', 8: '/', 12: '-'};
    final buf = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (seps.containsKey(i)) buf.write(seps[i]);
      buf.write(limited[i]);
    }
    return buf.toString();
  }
}
