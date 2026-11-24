import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/budget_comment_detail_view.dart';
import 'package:oflite/modules/budget/presenter/budget_comment_detail/budget_comment_detail_view_model.dart';
import 'package:oflite/modules/budget/presenter/strings/comment_pt_string.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/comment_library_creator_view.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/comment_library_picker_view.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

import 'budget_comment_list_view_model.dart';
import 'components/budget_comment_card.dart';
import 'components/budget_comment_selection_bar.dart';
import 'components/comment_form_dialog.dart';

class BudgetCommentListView extends StatefulWidget {
  final CustomerInfo item;

  const BudgetCommentListView({super.key, required this.item});

  @override
  State<BudgetCommentListView> createState() => _BudgetCommentListView();
}

class _BudgetCommentListView extends State<BudgetCommentListView> {
  late final BudgetCommentListViewModel _viewModel;
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetCommentListViewModel(item: widget.item);
    _viewModel.deleteCommand.addListener(_onDeleteChanged);
    _initData();
  }

  @override
  void dispose() {
    _viewModel.deleteCommand.removeListener(_onDeleteChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final success = await _viewModel.loadComments();
    if (!success && mounted) {
      await _displayAlert.notificationError(
        context,
        CommentStrings.errorTitle,
        CommentStrings.loadError,
      );
    }
  }

  // --- Remoção em massa ---
  Future<void> _onDeleteChanged() async {
    final cmd = _viewModel.deleteCommand;
    if (!mounted || cmd.running) return;
    if (cmd.completed) {
      cmd.clearResult();
      await _displayAlert.notificationNotCloseScreen(
        context,
        CommentStrings.successTitle,
        CommentStrings.removeSuccess,
      );
    } else if (cmd.error) {
      cmd.clearResult();
      await _displayAlert.notificationError(
        context,
        CommentStrings.errorTitle,
        CommentStrings.removeError,
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showConfirmBottomModal(
      context,
      title: CommentStrings.removeTitle(_viewModel.selectedCount),
      message: CommentStrings.removeMessage,
    );
    if (!confirm || !mounted) return;
    await _viewModel.deleteCommand.execute();
  }

  // --- Detalhe (ver / editar / excluir) ---
  Future<void> _openDetail(ObservationBudget comment) async {
    final result = await showBudgetCommentDetailBottomModal(
      context,
      budgetId: widget.item.id!,
      comment: comment,
    );
    if (!mounted) return;
    switch (result) {
      case BudgetCommentDetailResult.delete:
        _viewModel.markForDelete(comment);
      case BudgetCommentDetailResult.saved:
        await _viewModel.loadComments();
        if (!mounted) return;
        await _displayAlert.notificationNotCloseScreen(
          context,
          CommentStrings.successTitle,
          CommentStrings.successUpdateMessage,
        );
      case null:
        break;
    }
  }

  // --- Adicionar ---
  Future<void> _openCommentForm(ObservationBudget comment) async {
    final saved = await showCommentFormDialog(
      context: context,
      viewModel: _viewModel,
      comment: comment,
      displayAlert: _displayAlert,
    );
    if (saved == null) return;
    await _viewModel.loadComments();
  }

  /// "+" do orçamento — mesmo fluxo do `_addItem()` da lista de itens:
  /// lista com comentários → escolher criar/selecionar; vazia → criar.
  /// Free continua no modal antigo, sem IA.
  Future<void> _addComment() async {
    if (!_viewModel.hasCommentLibrary) {
      await _openCommentForm(
        ObservationBudget()
          ..checkbox = false
          ..id = ''
          ..data = ''
          ..uid = ''
          ..observacao = '',
      );
      return;
    }
    if (await _viewModel.getLibraryCount() > 0) {
      if (!mounted) return;
      final value = await _displayAlert.listNotification(
        context,
        title: CommentLibraryStrings.optionTitle,
        createLabel: CommentLibraryStrings.optionCreate,
        selectLabel: CommentLibraryStrings.optionSelect,
      );
      if (value == CommentLibraryStrings.optionCreate) {
        await _createFromLibrary();
      } else if (value == CommentLibraryStrings.optionSelect) {
        await _openCommentLibrary();
      }
    } else {
      await _createFromLibrary();
    }
  }

  Future<void> _createFromLibrary() async {
    final saved = await showCommentLibraryCreatorBottomModal(
      context,
      budgetId: widget.item.id!,
    );
    await _viewModel.loadComments();
    if (saved == null || !mounted) return;
    await _displayAlert.notificationNotCloseScreen(
      context,
      CommentLibraryStrings.doneTitle,
      CommentLibraryStrings.savedAs(saved.name),
    );
  }

  Future<void> _openCommentLibrary() async {
    final added = await showCommentLibraryPickerBottomModal(
      context,
      budgetId: widget.item.id!,
    );
    if (!added || !mounted) return;
    await _viewModel.loadComments();
    if (!mounted) return;
    await _displayAlert.notificationNotCloseScreen(
      context,
      CommentLibraryStrings.doneTitle,
      CommentLibraryStrings.addedToBudget,
    );
  }

  Widget _buildList() {
    final list = _viewModel.observation;
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _viewModel.loadComments,
      child:
          list.isEmpty
              ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 16,
                    ),
                    child: Text(
                      CommentStrings.emptyList,
                      style: const TextStyle(
                        fontSize: 14,
                        color: emptyTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
              : AppAdaptiveGrid(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final comment = list[index];
                  return BudgetCommentCard(
                    comment: comment,
                    selected: _viewModel.isSelected(comment),
                    onTap:
                        () =>
                            _viewModel.selectionMode
                                ? _viewModel.toggleSelect(comment)
                                : _openDetail(comment),
                    onToggleSelect: () => _viewModel.toggleSelect(comment),
                  );
                },
              ),
    );
  }

  Widget _buildFab() {
    if (_viewModel.selectionMode) {
      final deleting = _viewModel.deleteCommand.running;
      return FloatingActionButton.extended(
        heroTag: 'remover_comentarios',
        onPressed: deleting ? null : _confirmDelete,
        backgroundColor: statusRejectedColor,
        shape: const StadiumBorder(),
        icon:
            deleting
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: whiteColor,
                  ),
                )
                : const Icon(Icons.delete_outline_rounded, color: whiteColor),
        label: Text(
          CommentStrings.removeCount(_viewModel.selectedCount),
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'adicionar_comentario',
      onPressed: _addComment,
      backgroundColor: buttonColor,
      elevation: 4,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.add, color: blackColor, size: 20),
      label: Text(
        CommentStrings.newComment,
        style: const TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, _viewModel.deleteCommand]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: Column(
            children: <Widget>[
              AppHeaderSecondTitle(
                titlePage: CommentStrings.screenTitle,
                secondTitle: CommentStrings.screenSubtitle,
                onBack: () => Navigator.pop(context, true),
              ),
              if (_viewModel.selectionMode)
                BudgetCommentSelectionBar(
                  count: _viewModel.selectedCount,
                  allSelected: _viewModel.allSelected,
                  onCancel: _viewModel.clearSelection,
                  onToggleAll: _viewModel.selectAll,
                ),
              Expanded(child: _buildList()),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _buildFab(),
        );
      },
    );
  }
}
