import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/product/presenter/product_segment/components/product_segment_picker.dart';
import 'package:oflite/modules/product/presenter/product_segment/components/product_segment_review_list.dart';
import 'package:oflite/modules/product/presenter/product_segment/product_segment_view_model.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

/// Modal-tela (§19) que pergunta o ramo de atuação e monta a lista de preços
/// inicial com IA. Fecha com `true` quando salvou ou o usuário pulou.
class ProductSegmentView extends StatefulWidget {
  const ProductSegmentView({super.key});

  @override
  State<ProductSegmentView> createState() => _ProductSegmentViewState();
}

class _ProductSegmentViewState extends State<ProductSegmentView> {
  late final ProductSegmentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ProductSegmentViewModel();
    _viewModel.generateCommand.addListener(_onGenerateChanged);
    _viewModel.saveCommand.addListener(_onSaveChanged);
    _viewModel.skipCommand.addListener(_onSkipChanged);
  }

  void _onGenerateChanged() {
    if (!_viewModel.generateCommand.error) return;
    AlertSnackBar.error(
      context,
      ProductPtString.errorTitle,
      ProductPtString.segmentGenerateError,
    );
  }

  void _onSaveChanged() {
    final cmd = _viewModel.saveCommand;
    if (cmd.completed) {
      AlertSnackBar.success(
        context,
        ProductPtString.doneTitle,
        ProductPtString.segmentSavedMessage(_viewModel.items.length),
      );
      Navigator.pop(context, true);
    } else if (cmd.error) {
      AlertSnackBar.error(
        context,
        ProductPtString.errorTitle,
        ProductPtString.segmentSaveError,
      );
    }
  }

  void _onSkipChanged() {
    if (_viewModel.skipCommand.completed) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _viewModel.generateCommand.removeListener(_onGenerateChanged);
    _viewModel.saveCommand.removeListener(_onSaveChanged);
    _viewModel.skipCommand.removeListener(_onSkipChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _viewModel,
        _viewModel.generateCommand,
        _viewModel.saveCommand,
        _viewModel.skipCommand,
      ]),
      builder: (context, _) {
        final busy = _viewModel.busy;
        return AppBottomModal(
          title: _viewModel.title,
          buttonLabel: _viewModel.buttonLabel,
          buttonLoading: busy,
          onButtonPressed: _viewModel.onPrimaryPressed,
          scrollable: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (_viewModel.reviewing)
                ProductSegmentReviewList(
                  items: _viewModel.items,
                  formatPrice: _viewModel.formatPrice,
                  onRemove: _viewModel.removeItem,
                  enabled: !busy,
                )
              else
                ProductSegmentPicker(
                  selected: _viewModel.segment,
                  onSelected: _viewModel.selectSegment,
                  customController: _viewModel.customController,
                  enabled: !busy,
                  errorText: _viewModel.validationError,
                ),
              TextButton(
                onPressed: busy ? null : _viewModel.skipCommand.execute,
                child: Text(
                  ProductPtString.segmentSkip,
                  style: const TextStyle(color: AppBottomModal.grayColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Abre o [ProductSegmentView]. Retorna `true` quando salvou ou pulou.
Future<bool?> showProductSegmentBottomModal(BuildContext context) {
  return showAppModal<bool>(
    context,
    builder: (_) => const ProductSegmentView(),
  );
}
