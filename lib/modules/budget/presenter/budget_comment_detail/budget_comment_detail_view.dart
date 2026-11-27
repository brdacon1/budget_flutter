import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/budget_comment_detail_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/components/budget_comment_detail_actions.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/components/budget_comment_detail_sheet.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/components/budget_comment_detail_text_field.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/components/comment_library_improve_button.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Modal-tela (§19) do comentário do orçamento, no visual do modal de ações
/// da lista de orçamentos. Abre em leitura com Excluir/Editar; "Editar"
/// libera o campo (e o "Melhorar com IA" para assinante).
class BudgetCommentDetailView extends StatefulWidget {
  const BudgetCommentDetailView({
    super.key,
    required this.budgetId,
    required this.comment,
  });

  final String budgetId;
  final ObservationBudget comment;

  @override
  State<BudgetCommentDetailView> createState() =>
      _BudgetCommentDetailViewState();
}

class _BudgetCommentDetailViewState extends State<BudgetCommentDetailView> {
  late final BudgetCommentDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetCommentDetailViewModel(
      budgetId: widget.budgetId,
      comment: widget.comment,
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
    if (cmd.completed) {
      Navigator.of(context).pop(BudgetCommentDetailResult.saved);
    } else if (cmd.error) {
      cmd.clearResult();
      if (_viewModel.emptyError) return; // erro inline
      AlertSnackBar.error(
        context,
        CommentStrings.errorTitle,
        CommentStrings.errorUpdateMessage,
      );
    }
  }

  Future<void> _onImproveChanged() async {
    final cmd = _viewModel.improveCommand;
    if (!mounted || cmd.running) return;
    if (cmd.result case Error(:final error)) {
      cmd.clearResult();
      AlertSnackBar.warning(
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
    if (!_viewModel.dirty) {
      _viewModel.cancelEditing();
      return;
    }
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
        return BudgetCommentDetailSheet(
          date: widget.comment.data ?? '',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BudgetCommentDetailTextField(
                controller: _viewModel.textController,
                editing: _viewModel.editing,
                enabled: !_viewModel.busy,
                errorText:
                    _viewModel.emptyError
                        ? CommentStrings.emptyTextError
                        : null,
              ),
              if (_viewModel.showImprove)
                CommentLibraryImproveButton(
                  loading: _viewModel.improveCommand.running,
                  canUndo: _viewModel.canUndo,
                  enabled: !_viewModel.busy,
                  onImprove: _viewModel.improveCommand.execute,
                  onUndo: _viewModel.undoImprove,
                  color: whiteColor,
                ),
            ],
          ),
          actions: BudgetCommentDetailActions(
            editing: _viewModel.editing,
            busy: _viewModel.busy,
            saving: _viewModel.saveCommand.running,
            onDelete:
                () =>
                    Navigator.of(context).pop(BudgetCommentDetailResult.delete),
            onEdit: _viewModel.startEditing,
            onCancel: _viewModel.cancelEditing,
            onSave: _save,
          ),
        );
      },
    );
  }
}
