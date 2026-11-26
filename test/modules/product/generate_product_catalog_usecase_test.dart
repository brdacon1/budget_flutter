import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/modules/product/domain/entity/business_segment.dart';
import 'package:oflite/modules/product/domain/entity/item_category.dart';
import 'package:oflite/modules/product/domain/usecase/generate_product_catalog_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeAi implements GenerateAiTextUsecase {
  _FakeAi(this.reply);

  final Result<String> reply;
  String? lastPrompt;

  @override
  Future<Result<String>> call({
    required String system,
    required String prompt,
    int maxOutputTokens = 512,
    List<String>? jsonKeys,
    bool asList = false,
    DateTime? now,
  }) async {
    lastPrompt = prompt;
    return reply;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<Result<List<dynamic>>> run(_FakeAi ai, {String? custom}) =>
      GenerateProductCatalogUsecase(ai)(
        segment:
            custom == null ? BusinessSegment.painting : BusinessSegment.other,
        customName: custom,
        languageCode: 'pt',
      );

  test('converte o JSON em itens e descarta unidade/preço inválidos', () async {
    final ai = _FakeAi(
      const Result.ok(
        '[{"descricao":"Pintura de parede","unidade":"m²","categoria":"servico","preco":"25,5"},'
        '{"descricao":"Tinta","unidade":"lata","categoria":"produto","preco":"100"},'
        '{"descricao":"Massa","unidade":"un","categoria":"produto","preco":"-1"},'
        '{"descricao":"Rolo","unidade":"un","categoria":"produto","preco":"12"}]',
      ),
    );
    final result = await run(ai);
    final items = (result as Ok<List<dynamic>>).value;
    expect(items.map((i) => i.descricao), ['Pintura de parede', 'Rolo']);
    expect(items.first.preco, 25.5);
    expect(items.first.categoria, ItemCategory.services.value);
    expect(items.last.categoria, ItemCategory.products.value);
    expect(ai.lastPrompt, contains('pintura'));
  });

  test('JSON inválido ou lista vazia vira erro', () async {
    expect(await run(_FakeAi(const Result.ok('não é json'))), isA<Error>());
    expect(await run(_FakeAi(const Result.ok('[]'))), isA<Error>());
  });

  test('"Outro" sem texto não chama a IA', () async {
    final ai = _FakeAi(const Result.ok('[]'));
    expect(await run(ai, custom: '  '), isA<Error>());
    expect(ai.lastPrompt, isNull);
  });
}
