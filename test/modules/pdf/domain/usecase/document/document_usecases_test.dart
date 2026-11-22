import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/document_validation_result.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/format_document_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/validate_document_usecase.dart';

void main() {
  const validate = ValidateDocumentUsecase();
  const format = FormatDocumentUsecase();

  group('ValidateDocumentUsecase', () {
    test('vazio', () {
      expect(validate('').error, DocumentValidationError.empty);
      expect(validate(null).error, DocumentValidationError.empty);
    });

    test('CPF válido com e sem máscara', () {
      final r = validate('529.982.247-25');
      expect(r.isValid, isTrue);
      expect(r.type, DocumentType.cpf);
      expect(r.cleaned, '52998224725');
      expect(validate('52998224725').isValid, isTrue);
    });

    test('CPF inválido e repetido', () {
      expect(
        validate('529.982.247-24').error,
        DocumentValidationError.invalidCpf,
      );
      expect(
        validate('111.111.111-11').error,
        DocumentValidationError.invalidCpf,
      );
    });

    test('CNPJ numérico válido/inválido', () {
      final r = validate('11.222.333/0001-81');
      expect(r.isValid, isTrue);
      expect(r.type, DocumentType.cnpj);
      expect(
        validate('11.222.333/0001-80').error,
        DocumentValidationError.invalidCnpj,
      );
      expect(
        validate('00.000.000/0000-00').error,
        DocumentValidationError.invalidCnpj,
      );
    });

    test('CNPJ alfanumérico válido', () {
      final r = validate('12.abc.345/01de-35');
      expect(r.isValid, isTrue);
      expect(r.cleaned, '12ABC34501DE35');
    });

    test('tamanho errado', () {
      expect(validate('123').error, DocumentValidationError.invalidLength);
    });
  });

  group('FormatDocumentUsecase', () {
    test('formata CPF e CNPJ', () {
      expect(format('52998224725', DocumentType.cpf), '529.982.247-25');
      expect(format('11222333000181', DocumentType.cnpj), '11.222.333/0001-81');
      expect(format('12ABC34501DE35', DocumentType.cnpj), '12.ABC.345/01DE-35');
    });

    test('máscara parcial alterna CPF -> CNPJ', () {
      expect(format.partial('5299'), '529.9');
      expect(format.partial('52998224725'), '529.982.247-25');
      expect(format.partial('112223330001'), '11.222.333/0001');
      expect(format.partial('12abc'), '12.ABC');
      expect(format.partial('112223330001819999'), '11.222.333/0001-81');
    });
  });
}
