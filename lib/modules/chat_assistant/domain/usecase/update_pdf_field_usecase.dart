import 'dart:async';

import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Atualiza um campo específico do PDF da empresa (OwnerPdf).
///
/// Campos suportados: 'name' (empresa), 'phone' (fone), 'email', 'cnpj'.
class UpdatePdfFieldUsecase {
  final PdfRepository _pdfRepo;

  const UpdatePdfFieldUsecase(this._pdfRepo);

  /// Atualiza o campo [field] com o [value] informado.
  /// Retorna o OwnerPdf atualizado ou erro.
  Future<Result<OwnerPdf>> call(
    String field,
    String value,
  ) async {
    // 1. Busca o OwnerPdf atual
    final fetchResult = await _pdfRepo.fetchInformationEnterprise();
    if (fetchResult is Error<OwnerPdf>) {
      return Result.error(fetchResult.error);
    }

    final current = (fetchResult as Ok<OwnerPdf>).value;

    // 2. Atualiza apenas o campo solicitado
    final updated = _updateField(current, field, value);

    // 3. Persiste
    final saveResult = await _pdfRepo.saveInformationEnterprise(updated);
    if (saveResult is Error<void>) {
      return Result.error(saveResult.error);
    }

    return Result.ok(updated);
  }

  OwnerPdf _updateField(OwnerPdf current, String field, String value) {
    switch (field) {
      case 'name':
        return OwnerPdf(
          rua: current.rua,
          empresa: value,
          email: current.email,
          cnpj: current.cnpj,
          bairro: current.bairro,
          city: current.city,
          cep: current.cep,
          fotoId: current.fotoId,
          fone: current.fone,
          logoName: current.logoName,
        );
      case 'phone':
        return OwnerPdf(
          rua: current.rua,
          empresa: current.empresa,
          email: current.email,
          cnpj: current.cnpj,
          bairro: current.bairro,
          city: current.city,
          cep: current.cep,
          fotoId: current.fotoId,
          fone: value,
          logoName: current.logoName,
        );
      case 'email':
        return OwnerPdf(
          rua: current.rua,
          empresa: current.empresa,
          email: value,
          cnpj: current.cnpj,
          bairro: current.bairro,
          city: current.city,
          cep: current.cep,
          fotoId: current.fotoId,
          fone: current.fone,
          logoName: current.logoName,
        );
      case 'cnpj':
        return OwnerPdf(
          rua: current.rua,
          empresa: current.empresa,
          email: current.email,
          cnpj: value,
          bairro: current.bairro,
          city: current.city,
          cep: current.cep,
          fotoId: current.fotoId,
          fone: current.fone,
          logoName: current.logoName,
        );
      default:
        return current;
    }
  }
}
