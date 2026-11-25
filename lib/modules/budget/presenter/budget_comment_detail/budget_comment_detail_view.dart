import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/budget_comment_detail_view_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/components/budget_comment_detail_text_field.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/components/comment_library_improve_button.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/modules/core/ai_text/domain/entity/ai_text_exceptions.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/button/action_button.dart';
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

  Widget _buildActions() {
    if (!_viewModel.editing) {
      return Row(
        children: [
          Expanded(
            child: ActionButton(
              icon: Icons.delete_outline_rounded,
              label: CommentStrings.deleteLabel,
              backgroundColor: statusRejectedColor.withValues(alpha: 0.15),
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(BudgetCommentDetailResult.delete),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ActionButton(
              icon: Icons.edit_rounded,
              label: CommentStrings.editLabel,
              backgroundColor: buttonColor.withValues(alpha: 0.25),
              onPressed: _viewModel.startEditing,
            ),
          ),
        ],
      );
    }
    final saving = _viewModel.saveCommand.running;
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            icon: Icons.close_rounded,
            label: CommentStrings.cancelLabel,
            onPressed: _viewModel.busy ? () {} : _viewModel.cancelEditing,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ActionButton(
            icon: Icons.check_rounded,
            label: saving ? CommentStrings.saving : CommentStrings.saveLabel,
            backgroundColor: buttonColor.withValues(alpha: 0.25),
            onPressed: _save,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = (mq.size.height - mq.viewInsets.bottom) * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: SafeArea(
          top: false,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _viewModel,
              _viewModel.saveCommand,
              _viewModel.improveCommand,
            ]),
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: sheetHandleColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    CommentStrings.title,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    CommentStrings.dateLabel(widget.comment.data ?? ''),
                    style: const TextStyle(color: mutedTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: cardBorderColor, height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Abre o detalhe do comentário. `saved` → recarregar lista;
/// `delete` → marcar para remoção (fluxo em massa); `null` → nada.
Future<BudgetCommentDetailResult?> showBudgetCommentDetailBottomModal(
  BuildContext context, {
  required String budgetId,
  required ObservationBudget comment,
}) {
  return showAppModal<BudgetCommentDetailResult>(
    context,
    builder:
        (_) => BudgetCommentDetailView(budgetId: budgetId, comment: comment),
  );
}
