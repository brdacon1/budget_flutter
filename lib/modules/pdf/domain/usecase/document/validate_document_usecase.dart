import 'document_validation_result.dart';

/// Valida CPF (11 dígitos) ou CNPJ (14 caracteres, inclusive alfanumérico).
class ValidateDocumentUsecase {
  const ValidateDocumentUsecase();

  DocumentValidationResult call(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const DocumentValidationResult.invalid(
        DocumentValidationError.empty,
      );
    }

    final cleaned = value.replaceAll(RegExp(r'[.\/\-\s]'), '').toUpperCase();

    if (cleaned.length == 11 && RegExp(r'^\d{11}$').hasMatch(cleaned)) {
      return _validateCpf(cleaned)
          ? DocumentValidationResult.valid(DocumentType.cpf, cleaned)
          : const DocumentValidationResult.invalid(
            DocumentValidationError.invalidCpf,
            type: DocumentType.cpf,
          );
    }
    if (cleaned.length == 14) {
      return _validateCnpj(cleaned)
          ? DocumentValidationResult.valid(DocumentType.cnpj, cleaned)
          : const DocumentValidationResult.invalid(
            DocumentValidationError.invalidCnpj,
            type: DocumentType.cnpj,
          );
    }
    return const DocumentValidationResult.invalid(
      DocumentValidationError.invalidLength,
    );
  }

  bool _validateCpf(String cpf) {
    if (cpf == cpf[0] * 11) return false;

    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    var rest = sum % 11;
    final dv1 = rest < 2 ? 0 : 11 - rest;

    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    rest = sum % 11;
    final dv2 = rest < 2 ? 0 : 11 - rest;

    return cpf.substring(9) == '$dv1$dv2';
  }

  bool _validateCnpj(String cnpj) {
    if (!RegExp(r'^[A-Z0-9]{12}[0-9]{2}$').hasMatch(cnpj)) return false;
    if (RegExp(r'^(.)\1{11}').hasMatch(cnpj.substring(0, 12))) return false;

    final values = cnpj.split('').map(_cnpjCharValue).toList();

    const firstWeights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    var firstSum = 0;
    for (var i = 0; i < 12; i++) {
      firstSum += values[i] * firstWeights[i];
    }
    final firstDigit = firstSum % 11 < 2 ? 0 : 11 - (firstSum % 11);
    if (firstDigit != values[12]) return false;

    const secondWeights = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    var secondSum = 0;
    for (var i = 0; i < 13; i++) {
      secondSum += values[i] * secondWeights[i];
    }
    final secondDigit = secondSum % 11 < 2 ? 0 : 11 - (secondSum % 11);
    return secondDigit == values[13];
  }

  int _cnpjCharValue(String char) => char.codeUnitAt(0) - 48;
}
