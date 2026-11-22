import 'package:flutter/widgets.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_comment_repository.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// O que a tela de origem deve fazer quando o modal fecha.
enum BudgetCommentDetailResult { saved, delete }

/// Estado do modal de detalhe do comentário do orçamento.
///
/// Abre em leitura; "Editar" libera o campo. "Melhorar com IA" só para
/// assinante e com mais de [minTextToImprove] caracteres.
class BudgetCommentDetailViewModel extends ChangeNotifier {
  BudgetCommentDetailViewModel({required this.budgetId, required this.comment})
    : textController = TextEditingController(text: comment.observacao ?? '') {
    saveCommand = Command0<void>(_save);
    improveCommand = Command0<String>(_improve);
    textController.addListener(_onTextChanged);
  }

  static const minTextToImprove = 10;

  final String budgetId;
  final ObservationBudget comment;

  final BudgetCommentRepository _repo = getIt<BudgetCommentRepository>();
  final ImproveCommentTextUsecase _improveUsecase =
      getIt<ImproveCommentTextUsecase>();

  /// IA só para assinante (mesma regra da lista de comentários).
  late final bool canUseAi = getIt<CheckCommentLibraryAccessUsecase>()();

  final TextEditingController textController;

  late final Command0<void> saveCommand;
  late final Command0<String> improveCommand;

  bool editing = false;
  bool emptyError = false;

  String? _undoText;
  String? _improvedText;

  bool get canUndo => _undoText != null;
  bool get busy => saveCommand.running || improveCommand.running;

  bool get dirty => textController.text.trim() != (comment.observacao ?? '');

  bool get showImprove =>
      canUseAi &&
      editing &&
      (textController.text.trim().length > minTextToImprove ||
          improveCommand.running ||
          canUndo);

  void startEditing() {
    editing = true;
    notifyListeners();
  }

  /// Volta para leitura descartando o que foi digitado.
  void cancelEditing() {
    _undoText = null;
    _improvedText = null;
    emptyError = false;
    textController.text = comment.observacao ?? '';
    editing = false;
    notifyListeners();
  }

  void undoImprove() {
    final previous = _undoText;
    if (previous == null) return;
    _undoText = null;
    _improvedText = null;
    textController.text = previous;
  }

  void _onTextChanged() {
    if (_improvedText != null && textController.text != _improvedText) {
      _undoText = null;
      _improvedText = null;
    }
    emptyError = false;
    notifyListeners();
  }

  Future<Result<String>> _improve() async {
    final original = textController.text;
    final result = await _improveUsecase(original);
    if (result is Ok<String>) {
      _improvedText = result.value;
      textController.text = result.value;
      _undoText = original;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _save() async {
    final text = textController.text.trim();
    if (text.isEmpty) {
      emptyError = true;
      notifyListeners();
      return Result.error(Exception('empty'));
    }
    final updated =
        ObservationBudget(
            id: comment.id,
            observacao: text,
            data: comment.data,
            uid: comment.uid,
          )
          ..checkbox = false;
    return _repo.updateComment(budgetId, updated);
  }

  @override
  void dispose() {
    textController.dispose();
    saveCommand.dispose();
    improveCommand.dispose();
    super.dispose();
  }
}
