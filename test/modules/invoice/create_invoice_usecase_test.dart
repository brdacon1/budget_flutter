import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/invoice/data/model/invoice.dart';
import 'package:oflite/modules/invoice/domain/repository/invoice_repository.dart';
import 'package:oflite/modules/invoice/domain/usecase/create_invoice_usecase.dart';
import 'package:oflite/modules/invoice/domain/usecase/list_invoices_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/entity/payment_proof_type.dart';
import 'package:oflite/modules/payment_proof/domain/entity/proof_attachment.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeRepo implements InvoiceRepository {
  int count = 0;
  final saved = <Invoice>[];

  @override
  Future<Result<int>> countInvoices(String budgetId) async => Result.ok(count);

  @override
  Future<Result<void>> deleteInvoice(String budgetId, Invoice invoice) async =>
      const Result.ok(null);

  @override
  Future<Result<List<Invoice>>> fetchInvoices(String budgetId) async =>
      Result.ok(saved);

  @override
  Future<Result<Invoice>> saveInvoice({
    required String budgetId,
    required String id,
    required String localPath,
    required PaymentProofType type,
    required String name,
    required double value,
    required DateTime createdAt,
    required PaymentProofOrigin origin,
  }) async {
    final i = Invoice(
      id: id,
      name: name,
      value: value,
      type: type,
      fileUrl: 'u',
      storagePath: 'p',
      size: 1,
      createdAt: createdAt,
      origin: origin.value,
    );
    saved.add(i);
    return Result.ok(i);
  }
}

ProofAttachment _img(String n) => ProofAttachment(
  path: '/tmp/$n.jpg',
  name: '$n.jpg',
  type: PaymentProofType.image,
  size: 10,
);

void main() {
  test('nome e valor são obrigatórios', () async {
    final uc = CreateInvoiceUsecase(_FakeRepo());
    final noName = await uc(
      budgetId: 'b',
      files: [_img('a')],
      name: ' ',
      value: 10,
    );
    expect((noName as Error).error, isA<InvoiceNameRequired>());
    final noValue = await uc(
      budgetId: 'b',
      files: [_img('a')],
      name: 'Parafusos',
      value: 0,
    );
    expect((noValue as Error).error, isA<InvoiceValueRequired>());
  });

  test('2 fotos = 2 notas e a soma é o total a cobrar', () async {
    final repo = _FakeRepo();
    final res = await CreateInvoiceUsecase(repo)(
      budgetId: 'b',
      files: [_img('a'), _img('b')],
      name: 'Parafusos',
      value: 20,
    );
    expect((res as Ok<List<Invoice>>).value.map((i) => i.name), [
      'Parafusos (1)',
      'Parafusos (2)',
    ]);
    final list = await ListInvoicesUsecase(repo)('b');
    expect((list as Ok<InvoiceList>).value.total, 40);
  });

  test('limite de 15 por orçamento', () async {
    final repo = _FakeRepo()..count = 14;
    final res = await CreateInvoiceUsecase(repo)(
      budgetId: 'b',
      files: [_img('a'), _img('b')],
      name: 'x',
      value: 1,
    );
    expect((res as Error).error, isA<InvoiceLimitReached>());
  });
}
