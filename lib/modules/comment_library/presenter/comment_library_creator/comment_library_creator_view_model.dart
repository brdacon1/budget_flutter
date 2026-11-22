import 'package:flutter/widgets.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/entity/comment_library_exceptions.dart';
import 'package:oflite/modules/comment_library/domain/usecase/improve_comment_text_usecase.dart';
import 'package:oflite/modules/comment_library/domain/usecase/save_library_comment_usecase.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado do modal de criar/editar comentário da biblioteca.
///
/// - Criar: só o texto; o nome vem da IA ao salvar.
/// - Editar: nome + texto. Se o texto mudou e o nome não foi mexido, manda
///   `name: null` para a IA renomear pelo novo assunto.
/// - [budgetId]: criado a partir do orçamento → grava também nele.
class CommentLibraryCreatorViewModel extends ChangeNotifier {
  CommentLibraryCreatorViewModel({this.comment, this.budgetId})
    : nameController = TextEditingController(text: comment?.name ?? ''),
      textController = TextEditingController(text: comment?.text ?? '') {
    saveCommand = Command0<CommentLibraryModel>(_save);
    improveCommand = Command0<String>(_improve);
    textController.addListener(_onTextChanged);
    nameController.addListener(notifyListeners);
  }

  final CommentLibraryModel? comment;
  final String? budgetId;

  final SaveLibraryCommentUsecase _saveUsecase = getIt<SaveLibraryCommentUsecase>();
  final ImproveCommentTextUsecase _improveUsecase =
      getIt<ImproveCommentTextUsecase>();

  final TextEditingController nameController;
  final TextEditingController textController;

  late final Command0<CommentLibraryModel> saveCommand;
  late final Command0<String> improveCommand;

  static const maxTextLength = SaveLibraryCommentUsecase.maxTextLength;

  String? textError;

  /// Texto anterior ao "Melhorar"; enquanto não for `null` o botão vira
  /// "Desfazer". Some na primeira edição manual.
  String? _undoText;
  String? _improvedText;

  bool get isEdit => comment?.id != null;
  bool get canUndo => _undoText != null;
  bool get busy => saveCommand.running || improveCommand.running;

  String get title =>
      isEdit ? CommentLibraryStrings.editTitle : CommentLibraryStrings.createTitle;

  String get buttonLabel {
    if (saveCommand.running) return CommentLibraryStrings.saving;
    return isEdit
        ? CommentLibraryStrings.saveChangesButton
        : CommentLibraryStrings.saveButton;
  }

  bool get _textChanged => textController.text.trim() != (comment?.text ?? '');
  bool get _nameChanged => nameController.text.trim() != (comment?.name ?? '');

  bool get dirty =>
      isEdit ? _textChanged || _nameChanged : textController.text.trim().isNotEmpty;

  bool get canImprove => textController.text.trim().isNotEmpty && !busy;

  /// Mínimo de caracteres para o "Melhorar com IA" aparecer.
  static const minTextToImprove = 10;

  /// Esconde o botão com texto curto; mantém visível durante a chamada e
  /// enquanto houver "Desfazer".
  bool get showImprove =>
      textController.text.trim().length > minTextToImprove ||
      improveCommand.running ||
      canUndo;

  void _onTextChanged() {
    if (_improvedText != null && textController.text != _improvedText) {
      _undoText = null;
      _improvedText = null;
    }
    if (textError != null) textError = null;
    notifyListeners();
  }

  void undoImprove() {
    final previous = _undoText;
    if (previous == null) return;
    _undoText = null;
    _improvedText = null;
    textController.text = previous;
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

  Future<Result<CommentLibraryModel>> _save() async {
    final result = await _saveUsecase(
      id: comment?.id,
      text: textController.text,
      name: _nameToSend(),
      budgetId: isEdit ? null : budgetId,
    );
    if (result case Error(:final error)) {
      textError = switch (error) {
        CommentTextEmptyException() => CommentLibraryStrings.textEmptyError,
        CommentTextTooLongException(:final maxLength) =>
          CommentLibraryStrings.textTooLongError(maxLength),
        _ => null,
      };
      notifyListeners();
    }
    return result;
  }

  /// Criar → `null` (IA). Editar → nome do campo, ou `null` para a IA
  /// renomear quando o texto mudou e o nome ficou igual (ou foi apagado).
  String? _nameToSend() {
    if (!isEdit) return null;
    final name = nameController.text.trim();
    if (name.isEmpty || (_textChanged && !_nameChanged)) return null;
    return name;
  }

  @override
  void dispose() {
    nameController.dispose();
    textController.dispose();
    saveCommand.dispose();
    improveCommand.dispose();
    super.dispose();
  }
}
