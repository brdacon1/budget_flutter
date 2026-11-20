import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/payment_proof/data/model/payment_proof.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/modules/payment_proof/domain/repository/payment_proof_repository.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/check_proof_limit_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/create_payment_proof_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/parse_money_input_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeRepo implements PaymentProofRepository {
  int count = 0;
  int size = 1000;
  bool failOnSave = false;
  int failAtCall = -1;
  final saved = <PaymentProof>[];
  final deleted = <String>[];
  int _calls = 0;

  @override
  Future<Result<int>> countProofs(String budgetId) async => Result.ok(count);

  @override
  Future<Result<void>> deleteProof(String budgetId, PaymentProof proof) async {
    deleted.add(proof.id);
    return Result.ok(null);
  }

  @override
  Future<Result<List<PaymentProof>>> fetchProofs(String budgetId) async =>
      Result.ok(saved);

  @override
  Future<int> fileSize(String path) async => size;

  @override
  Future<Result<PaymentProof>> saveProof({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    double? value,
    String? comment,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  }) async {
    final call = _calls++;
    if (failOnSave || call == failAtCall) {
      return Result.error(Exception('fail'));
    }
    final p = PaymentProof(
      id: id,
      name: name,
      value: value,
      comment: comment,
      type: type,
      fileUrl: 'url',
      storagePath: 'path',
      size: 1,
      createdAt: createdAt,
      origin: origin.value,
    );
    saved.add(p);
    return Result.ok(p);
  }
}

ProofAttachment _img(String n) => ProofAttachment(
  path: '/tmp/$n.jpg',
  name: '$n.jpg',
  type: PaymentProofType.image,
  size: 10,
);

void main() {
  group('ParseMoneyInputUsecase', () {
    const parse = ParseMoneyInputUsecase();
    test('aceita formatos pt e en', () {
      expect(parse('150,00'), 150);
      expect(parse('R\$ 500'), 500);
      expect(parse('1.234,56'), 1234.56);
      expect(parse('1234.56'), 1234.56);
      expect(parse('1,234.56'), 1234.56);
      expect(parse('1.500'), 1500);
    });
    test('legenda vira nome e/ou valor', () {
      expect(parse.caption('Pagamento antecipado'), (
        name: 'Pagamento antecipado',
        value: null,
      ));
      expect(parse.caption('R\$ 500'), (name: null, value: 500.0));
      expect(parse.caption('Pix entrada R\$ 500'), (
        name: 'Pix entrada',
        value: 500.0,
      ));
      expect(parse.caption('Entrada - 150,00'), (name: 'Entrada', value: 150.0));
      expect(parse.caption('  '), (name: null, value: null));
    });

    test('recusa texto e zero', () {
      expect(parse('pago ontem'), isNull);
      expect(parse('0'), isNull);
      expect(parse(''), isNull);
      expect(parse('500 reais'), isNull);
    });
  });

  group('ValidateProofAttachmentsUsecase', () {
    late _FakeRepo repo;
    late ValidateProofAttachmentsUsecase validate;
    setUp(() {
      repo = _FakeRepo();
      validate = ValidateProofAttachmentsUsecase(repo);
    });

    test('3 fotos → mantém 2 e avisa', () async {
      final v = await validate([
        (path: 'a.jpg', mime: null),
        (path: 'b.png', mime: null),
        (path: 'c.jpg', mime: null),
      ]);
      expect(v.files.length, 2);
      expect(v.trimmed, isTrue);
      expect(v.isValid, isTrue);
    });

    test('foto + PDF → só o PDF, com aviso', () async {
      final v = await validate([
        (path: 'a.jpg', mime: null),
        (path: 'b.pdf', mime: null),
      ]);
      expect(v.files.single.isPdf, isTrue);
      expect(v.issue, ProofAttachmentIssue.mixed);
    });

    test('tipo inválido', () async {
      final v = await validate([(path: 'a.docx', mime: null)]);
      expect(v.issue, ProofAttachmentIssue.invalidType);
    });

    test('mime do compartilhamento decide o tipo', () async {
      final v = await validate([(path: 'tmp_file', mime: 'application/pdf')]);
      expect(v.files.single.isPdf, isTrue);
    });

    test('PDF maior que 10 MB é recusado', () async {
      repo.size = 11 * 1024 * 1024;
      final v = await validate([(path: 'a.pdf', mime: null)]);
      expect(v.issue, ProofAttachmentIssue.tooBig);
    });

    test('imagem grande passa (é comprimida no envio)', () async {
      repo.size = 20 * 1024 * 1024;
      final v = await validate([(path: 'a.jpg', mime: null)]);
      expect(v.isValid, isTrue);
    });
  });

  group('CheckProofLimitUsecase', () {
    test('14 + 2 não cabe; 13 + 2 cabe', () async {
      final repo = _FakeRepo()..count = 14;
      final check = CheckProofLimitUsecase(repo);
      var r = await check('b', adding: 2) as Ok<({int count, bool fits})>;
      expect(r.value.fits, isFalse);
      repo.count = 13;
      r = await check('b', adding: 2) as Ok<({int count, bool fits})>;
      expect(r.value.fits, isTrue);
    });
  });

  group('CreatePaymentProofUsecase', () {
    late _FakeRepo repo;
    late CreatePaymentProofUsecase create;
    setUp(() {
      repo = _FakeRepo();
      create = CreatePaymentProofUsecase(
        repo,
        now: () => DateTime(2026, 11, 20, 14, 30),
      );
    });

    test('nome obrigatório', () async {
      final r = await create(
        budgetId: 'b',
        files: [_img('a')],
        name: '  ',
        value: 10,
      );
      expect((r as Error).error, isA<PaymentProofNameRequired>());
      expect(repo.saved, isEmpty);
    });

    test('valor obrigatório', () async {
      final r = await create(
        budgetId: 'b',
        files: [_img('a')],
        name: 'Pix',
        value: null,
      );
      expect((r as Error).error, isA<PaymentProofValueRequired>());
      expect(repo.saved, isEmpty);
    });

    test('com valor e comentário', () async {
      final r = await create(
        budgetId: 'b',
        files: [_img('a')],
        name: 'Pix',
        value: 150,
        comment: 'pago ontem',
      );
      expect(r, isA<Ok>());
      expect(repo.saved.single.value, 150);
      expect(repo.saved.single.comment, 'pago ontem');
      expect(repo.saved.single.createdAt, DateTime(2026, 11, 20, 14, 30));
    });

    test('2 fotos = 2 documentos com sufixo e ids diferentes', () async {
      await create(
        budgetId: 'b',
        files: [_img('a'), _img('b')],
        name: 'Entrada',
        value: 500,
      );
      expect(repo.saved.map((p) => p.name), ['Entrada (1)', 'Entrada (2)']);
      expect(repo.saved[0].id, isNot(repo.saved[1].id));
      expect(repo.saved.every((p) => p.value == 500), isTrue);
    });

    test('limite de 15 por orçamento', () async {
      repo.count = 14;
      final r = await create(
        budgetId: 'b',
        files: [_img('a'), _img('b')],
        name: 'X',
        value: 1,
      );
      expect((r as Error).error, isA<PaymentProofLimitReached>());
    });

    test('falha no 2º arquivo desfaz o 1º', () async {
      repo.failAtCall = 1;
      final r = await create(
        budgetId: 'b',
        files: [_img('a'), _img('b')],
        name: 'X',
        value: 1,
      );
      expect(r, isA<Error>());
      expect(repo.deleted, [repo.saved.first.id]);
    });
  });
}
