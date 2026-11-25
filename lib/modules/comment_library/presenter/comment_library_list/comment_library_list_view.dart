import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_adaptive_grid.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_creator/comment_library_creator_view.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/comment_library_list_view_model.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/components/comment_library_card.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/components/comment_library_list_header.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/components/comment_library_selection_bar.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';

/// Tela de gestão da biblioteca de comentários (= lista de preço).
/// Toque edita; check circular marca para remover em lote.
class CommentLibraryListView extends StatefulWidget {
  const CommentLibraryListView({super.key});

  @override
  State<CommentLibraryListView> createState() => _CommentLibraryListViewState();
}

class _CommentLibraryListViewState extends State<CommentLibraryListView> {
  late final CommentLibraryListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CommentLibraryListViewModel();
    _viewModel.deleteCommand.addListener(_onDeleteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.load());
  }

  @override
  void dispose() {
    _viewModel.deleteCommand.removeListener(_onDeleteChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _onDeleteChanged() async {
    final cmd = _viewModel.deleteCommand;
    if (!mounted || cmd.running) return;
    if (cmd.completed) {
      cmd.clearResult();
      AlertSnackBar.success(
        context,
        CommentLibraryStrings.doneTitle,
        CommentLibraryStrings.deleteSuccess,
      );
    } else if (cmd.error) {
      cmd.clearResult();
      AlertSnackBar.error(
        context,
        CommentLibraryStrings.errorTitle,
        CommentLibraryStrings.deleteError,
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showConfirmBottomModal(
      context,
      title: CommentLibraryStrings.confirmRemoveTitle(_viewModel.selectedCount),
      message: CommentLibraryStrings.confirmRemoveMessage,
    );
    if (!confirm || !mounted) return;
    await _viewModel.deleteCommand.execute();
  }

  Future<void> _openCreator([CommentLibraryModel? comment]) async {
    final saved = await showCommentLibraryCreatorBottomModal(
      context,
      comment: comment,
    );
    await _viewModel.load();
    if (saved == null || !mounted) return;
    AlertSnackBar.success(
      context,
      CommentLibraryStrings.doneTitle,
      CommentLibraryStrings.savedAs(saved.name),
    );
  }

  Widget _buildFab() {
    if (_viewModel.selectionMode) {
      final deleting = _viewModel.deleteCommand.running;
      return FloatingActionButton.extended(
        heroTag: 'comment_library_delete',
        onPressed: deleting ? null : _confirmDelete,
        backgroundColor: statusRejectedColor,
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
          CommentLibraryStrings.removeSelected(_viewModel.selectedCount),
          style: const TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    return FloatingActionButton.extended(
      heroTag: 'comment_library_new',
      onPressed: _openCreator,
      backgroundColor: buttonColor,
      icon: const Icon(Icons.add, color: blackColor, size: 20),
      label: Text(
        CommentLibraryStrings.newComment,
        style: const TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildList() {
    final list = _viewModel.found;
    if (_viewModel.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: buttonColor));
    }
    final emptyText =
        _viewModel.loadFailed
            ? CommentLibraryStrings.loadError
            : CommentLibraryStrings.emptyList;
    return RefreshIndicator(
      color: refreshIndicatorColor,
      backgroundColor: bgColor,
      onRefresh: _viewModel.load,
      child:
          list.isEmpty
              ? ListView(
                children: [
                  const SizedBox(height: 80),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: emptyTextColor, fontSize: 15),
                  ),
                ],
              )
              : AppAdaptiveGrid(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 160),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final c = list[index];
                  return CommentLibraryCard(
                    comment: c,
                    selected: _viewModel.isSelected(c),
                    onTap:
                        () =>
                            _viewModel.selectionMode
                                ? _viewModel.toggleSelect(c)
                                : _openCreator(c),
                    onToggleSelect: () => _viewModel.toggleSelect(c),
                  );
                },
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
            children: [
              CommentLibraryListHeader(
                searchController: _viewModel.searchController,
                onBack: () => Navigator.pop(context),
                onSearchChanged: (_) => _viewModel.onSearchChanged(),
              ),
              if (_viewModel.selectionMode)
                CommentLibrarySelectionBar(
                  count: _viewModel.selectedCount,
                  allSelected: _viewModel.allFilteredSelected,
                  onCancel: _viewModel.clearSelection,
                  onToggleAll: _viewModel.selectAllFiltered,
                ),
              Expanded(child: _buildList()),
            ],
          ),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }
}
