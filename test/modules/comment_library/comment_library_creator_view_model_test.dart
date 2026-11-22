import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/save_library_comment_usecase.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/comment_library_creator_view_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeSave implements SaveLibraryCommentUsecase {
  ({String? id, String text, String? name, String? budgetId})? last;

  @override
  Future<Result<CommentLibraryModel>> call({
    String? id,
    required String text,
    String? name,
    String? budgetId,
  }) async {
    last = (id: id, text: text, name: name, budgetId: budgetId);
    return Result.ok(CommentLibraryModel(id: id ?? 'x', name: name ?? 'IA', text: text));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImprove implements ImproveCommentTextUsecase {
  Result<String> reply = const Result.ok('Texto melhorado');

  @override
  Future<Result<String>> call(String text) async => reply;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeSave save;
  late _FakeImprove improve;

  setUp(() async {
    await getIt.reset();
    save = _FakeSave();
    improve = _FakeImprove();
    getIt.registerSingleton<SaveLibraryCommentUsecase>(save);
    getIt.registerSingleton<ImproveCommentTextUsecase>(improve);
  });

  const existing = CommentLibraryModel(id: 'c1', name: 'Garantia', text: 'garantia 90 dias');

  test('criar: manda nome null (IA) e budgetId', () async {
    final vm = CommentLibraryCreatorViewModel(budgetId: 'b1');
    vm.textController.text = 'Prazo 10 dias';
    await vm.saveCommand.execute();
    expect(save.last!.name, isNull);
    expect(save.last!.budgetId, 'b1');
  });

  test('editar só o texto: nome null para a IA renomear', () async {
    final vm = CommentLibraryCreatorViewModel(comment: existing, budgetId: 'b1');
    vm.textController.text = 'Pagamento à vista';
    await vm.saveCommand.execute();
    expect(save.last!.name, isNull);
    expect(save.last!.id, 'c1');
    expect(save.last!.budgetId, isNull);
  });

  test('editar o nome: respeita o nome do usuário', () async {
    final vm = CommentLibraryCreatorViewModel(comment: existing);
    vm.nameController.text = 'Meu nome';
    vm.textController.text = 'outro texto';
    await vm.saveCommand.execute();
    expect(save.last!.name, 'Meu nome');
  });

  test('dirty', () {
    final create = CommentLibraryCreatorViewModel();
    expect(create.dirty, isFalse);
    create.textController.text = 'a';
    expect(create.dirty, isTrue);

    final edit = CommentLibraryCreatorViewModel(comment: existing);
    expect(edit.dirty, isFalse);
    edit.nameController.text = 'x';
    expect(edit.dirty, isTrue);
  });

  test('botão Melhorar só aparece com mais de 10 caracteres', () {
    final vm = CommentLibraryCreatorViewModel();
    expect(vm.showImprove, isFalse);
    vm.textController.text = '1234567890';
    expect(vm.showImprove, isFalse);
    vm.textController.text = '12345678901';
    expect(vm.showImprove, isTrue);
  });

  test('melhorar → desfazer volta ao original', () async {
    final vm = CommentLibraryCreatorViewModel();
    vm.textController.text = 'original';
    await vm.improveCommand.execute();
    expect(vm.textController.text, 'Texto melhorado');
    expect(vm.canUndo, isTrue);
    vm.undoImprove();
    expect(vm.textController.text, 'original');
    expect(vm.canUndo, isFalse);
  });

  test('edição manual após melhorar remove o desfazer', () async {
    final vm = CommentLibraryCreatorViewModel();
    vm.textController.text = 'original';
    await vm.improveCommand.execute();
    vm.textController.text = 'Texto melhorado!';
    expect(vm.canUndo, isFalse);
  });

  test('falha ao melhorar mantém o texto', () async {
    improve.reply = Result.error(Exception('timeout'));
    final vm = CommentLibraryCreatorViewModel();
    vm.textController.text = 'original';
    await vm.improveCommand.execute();
    expect(vm.textController.text, 'original');
    expect(vm.improveCommand.error, isTrue);
  });
}
