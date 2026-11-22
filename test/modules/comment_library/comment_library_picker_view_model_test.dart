import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/repository/comment_library_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/add_library_comments_to_budget_usecase.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/comment_library_picker_view_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

const _a = CommentLibraryModel(id: '1', name: 'Garantia', text: '90 dias');
const _b = CommentLibraryModel(id: '2', name: 'Pagamento', text: 'à vista no pix');

class _FakeRepo implements CommentLibraryRepository {
  @override
  Future<Result<List<CommentLibraryModel>>> fetchComments() async =>
      const Result.ok([_a, _b]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdd implements AddLibraryCommentsToBudgetUsecase {
  String? budgetId;
  List<CommentLibraryModel>? comments;

  @override
  Future<Result<void>> call(String id, List<CommentLibraryModel> c) async {
    budgetId = id;
    comments = c;
    return const Result.ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeAdd add;

  setUp(() async {
    await getIt.reset();
    add = _FakeAdd();
    getIt.registerSingleton<CommentLibraryRepository>(_FakeRepo());
    getIt.registerSingleton<AddLibraryCommentsToBudgetUsecase>(add);
  });

  test('busca por nome e por texto', () async {
    final vm = CommentLibraryPickerViewModel(budgetId: 'b1');
    await vm.load();
    vm.searchController.text = 'garan';
    expect(vm.found, [_a]);
    vm.searchController.text = 'pix';
    expect(vm.found, [_b]);
  });

  test('toggle e adiciona na ordem do toque', () async {
    final vm = CommentLibraryPickerViewModel(budgetId: 'b1');
    await vm.load();
    vm.toggle(_b);
    vm.toggle(_a);
    vm.toggle(_a);
    vm.toggle(_a);
    expect(vm.selectedCount, 2);
    await vm.addAllCommand.execute();
    expect(add.budgetId, 'b1');
    expect(add.comments, [_b, _a]);
    expect(vm.addAllCommand.completed, isTrue);
  });
}
