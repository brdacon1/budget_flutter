import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/domain/entity/comment_library_exceptions.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/comment_library_creator_view_model.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/components/comment_library_improve_button.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/components/comment_library_text_field.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Modal-tela (§19) de criar/editar comentário da biblioteca.
///
/// Quem salva é o modal: sucesso → `pop(comentário salvo)`; erro → continua
/// aberto com o texto. "Melhorar com IA" só troca o texto do campo.
class CommentLibraryCreatorView extends StatefulWidget {
  const CommentLibraryCreatorView({super.key, this.comment, this.budgetId});

  final CommentLibraryModel? comment;
  final String? budgetId;

  @override
  State<CommentLibraryCreatorView> createState() =>
      _CommentLibraryCreatorViewState();
}

class _CommentLibraryCreatorViewState extends State<CommentLibraryCreatorView> {
  late final CommentLibraryCreatorViewModel _viewModel;
  final DisplayAlertRepository _alert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = CommentLibraryCreatorViewModel(
      comment: widget.comment,
      budgetId: widget.budgetId,
    );
    _viewModel.saveCommand.addListener(_onSaveChanged);
    _viewModel.improveCommand.addListener(_onImproveChanged);
  }

  @override
  void dispose() {
    _viewModel.saveCommand.removeListener(_onSaveChanged);
    _viewModel.improveCommand.removeListener(_onImproveChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onSaveChanged() async {
    final cmd = _viewModel.saveCommand;
    if (!mounted || cmd.running) return;
    final result = cmd.result;
    if (result is Ok<CommentLibraryModel>) {
      Navigator.of(context).pop(result.value);
    } else if (result case Error(:final error)) {
      cmd.clearResult();
      if (error is CommentTextEmptyException ||
          error is CommentTextTooLongException) {
        return; // erro inline no campo
      }
      if (error is CommentSavedButNotLinkedException) {
        await _alert.notificationWarning(
          context,
          CommentLibraryStrings.warningTitle,
          CommentLibraryStrings.savedNotLinked,
        );
        // Já está na biblioteca: fecha para não duplicar num novo "Salvar".
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await _alert.notificationError(
        context,
        CommentLibraryStrings.errorTitle,
        CommentLibraryStrings.saveError,
      );
    }
  }

  Future<void> _onImproveChanged() async {
    final cmd = _viewModel.improveCommand;
    if (!mounted || cmd.running) return;
    if (cmd.result case Error(:final error)) {
      cmd.clearResult();
      await _alert.notificationWarning(
        context,
        CommentLibraryStrings.warningTitle,
        error is AiTextDailyLimitException
            ? CommentLibraryStrings.improveLimit
            : CommentLibraryStrings.improveError,
      );
    }
  }

  void _save() {
    if (_viewModel.busy) return;
    FocusScope.of(context).unfocus();
    _viewModel.saveCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _viewModel,
        _viewModel.saveCommand,
        _viewModel.improveCommand,
      ]),
      builder: (context, _) {
        return AppBottomModal(
          title: _viewModel.title,
          buttonLabel: _viewModel.buttonLabel,
          buttonVisible: _viewModel.dirty || _viewModel.saveCommand.running,
          onButtonPressed: _save,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_viewModel.isEdit) ...[
                  CommentLibraryTextField(
                    controller: _viewModel.nameController,
                    label: CommentLibraryStrings.nameLabel,
                    hint: CommentLibraryStrings.nameHint,
                    maxLength: 40,
                    enabled: !_viewModel.busy,
                  ),
                  const SizedBox(height: 12),
                ],
                CommentLibraryTextField(
                  controller: _viewModel.textController,
                  label: CommentLibraryStrings.textLabel,
                  hint: CommentLibraryStrings.textHint,
                  errorText: _viewModel.textError,
                  maxLength: CommentLibraryCreatorViewModel.maxTextLength,
                  multiline: true,
                  enabled: !_viewModel.busy,
                ),
                if (_viewModel.showImprove) ...[
                  const SizedBox(height: 4),
                  CommentLibraryImproveButton(
                    loading: _viewModel.improveCommand.running,
                    canUndo: _viewModel.canUndo,
                    enabled: _viewModel.canImprove,
                    onImprove: _viewModel.improveCommand.execute,
                    onUndo: _viewModel.undoImprove,
                  ),
                ],
                if (!_viewModel.isEdit) ...[
                  const SizedBox(height: 8),
                  Text(
                    CommentLibraryStrings.nameByAiInfo,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Abre o modal de criar/editar. Retorna o comentário salvo, ou `null` se
/// fechou sem salvar (ou salvou sem vincular — já avisado no modal).
Future<CommentLibraryModel?> showCommentLibraryCreatorBottomModal(
  BuildContext context, {
  CommentLibraryModel? comment,
  String? budgetId,
}) {
  return showModalBottomSheet<CommentLibraryModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) =>
            CommentLibraryCreatorView(comment: comment, budgetId: budgetId),
  );
}
