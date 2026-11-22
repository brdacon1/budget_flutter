/// Tipo de documento da empresa. O valor persistido continua em `OwnerPdf.cnpj`.
enum DocumentType { cpf, cnpj }

/// Motivo de um documento inválido (sem texto de UI — o presenter traduz).
enum DocumentValidationError { empty, invalidCpf, invalidCnpj, invalidLength }

class DocumentValidationResult {
  final DocumentType? type;
  final String? cleaned;
  final DocumentValidationError? error;

  const DocumentValidationResult.valid(this.type, this.cleaned) : error = null;

  const DocumentValidationResult.invalid(this.error, {this.type})
    : cleaned = null;

  bool get isValid => error == null;
}
