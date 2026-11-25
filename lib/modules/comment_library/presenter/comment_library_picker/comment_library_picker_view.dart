import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/comment_library_picker_view_model.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/components/comment_library_picker_card.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/components/comment_library_picker_footer.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_picker/components/comment_library_picker_header.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Modal-tela (§19) para **selecionar** comentários da biblioteca e copiá-los
/// para o orçamento — mesmo visual e comportamento do
/// `ProductPricePickerView`, sem quantidade e sem total.
class CommentLibraryPickerView extends StatefulWidget {
  const CommentLibraryPickerView({super.key, required this.budgetId});

  final String budgetId;

  @override
  State<CommentLibraryPickerView> createState() =>
      _CommentLibraryPickerViewState();
}

class _CommentLibraryPickerViewState extends State<CommentLibraryPickerView> {
  /// Mesma altura do picker da lista de preço.
  static const double _heightFactor = 0.67;

  late final CommentLibraryPickerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CommentLibraryPickerViewModel(budgetId: widget.budgetId);
    _viewModel.addAllCommand.addListener(_onAddAllChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.addAllCommand.removeListener(_onAddAllChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onAddAllChanged() {
    final cmd = _viewModel.addAllCommand;
    if (!mounted || cmd.running) return;
    if (cmd.completed) {
      Navigator.of(context).pop(true);
    } else if (cmd.error) {
      AlertSnackBar.error(
        context,
        CommentLibraryStrings.errorTitle,
        CommentLibraryStrings.addToBudgetError,
      );
      cmd.clearResult();
    }
  }

  void _addAll() {
    final cmd = _viewModel.addAllCommand;
    if (cmd.running || _viewModel.selectedCount == 0) return;
    cmd.execute();
  }

  Widget _buildList() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: buttonColor));
    }
    final list = _viewModel.found;
    if (list.isEmpty) {
      return Center(
        child: Text(
          CommentLibraryStrings.pickerEmpty,
          style: GoogleFonts.heebo(color: emptyTextColor, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 4, bottom: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        return CommentLibraryPickerCard(
          comment: c,
          selected: _viewModel.isSelected(c),
          onTap: () => _viewModel.toggle(c),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final height = (mq.size.height - mq.viewInsets.bottom) * _heightFactor;

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_viewModel, _viewModel.addAllCommand]),
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CommentLibraryPickerHeader(
                  searchController: _viewModel.searchController,
                  onSearchChanged: (_) => _viewModel.onSearchChanged(),
                  onClose: () => Navigator.of(context).pop(false),
                ),
                Expanded(child: _buildList()),
                if (_viewModel.selectedCount > 0)
                  CommentLibraryPickerFooter(
                    count: _viewModel.selectedCount,
                    loading: _viewModel.addAllCommand.running,
                    onAddAll: _addAll,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Abre o [CommentLibraryPickerView]. Retorna `true` quando os comentários
/// foram adicionados ao orçamento (a tela de origem recarrega).
Future<bool> showCommentLibraryPickerBottomModal(
  BuildContext context, {
  required String budgetId,
}) async {
  final added = await showAppModal<bool>(
    context,
    builder: (context) => CommentLibraryPickerView(budgetId: budgetId),
  );
  return added ?? false;
}
