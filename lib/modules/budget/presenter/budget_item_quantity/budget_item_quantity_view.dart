import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/form/app_form_save_button.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

import 'budget_item_quantity_view_model.dart';
import 'components/budget_item_quantity_input.dart';
import 'components/budget_item_quantity_read_only_field.dart';

/// Modal-tela (§19) de detalhes do item do orçamento com a quantidade
/// editável. Dados do item só como texto; a quantidade em destaque e o total
/// do item recalculado ao vivo. Salva via [BudgetItemQuantityViewModel] e
/// fecha retornando `true` para a tela de origem recarregar os totais.
class BudgetItemQuantityView extends StatefulWidget {
  const BudgetItemQuantityView({
    super.key,
    required this.budgetId,
    required this.item,
  });

  final String budgetId;
  final ItemsBudget item;

  @override
  State<BudgetItemQuantityView> createState() => _BudgetItemQuantityViewState();
}

class _BudgetItemQuantityViewState extends State<BudgetItemQuantityView> {
  late final BudgetItemQuantityViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BudgetItemQuantityViewModel(
      budgetId: widget.budgetId,
      item: widget.item,
    );
    _viewModel.saveCommand.addListener(_onSaveChanged);
  }

  @override
  void dispose() {
    _viewModel.saveCommand.removeListener(_onSaveChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onSaveChanged() {
    final cmd = _viewModel.saveCommand;
    if (!mounted || cmd.running) return;
    if (cmd.completed) {
      Navigator.of(context).pop(true);
    } else if (cmd.error) {
      AlertSnackBar.error(
        context,
        BudgetStrings.itemQuantityErrorTitle,
        BudgetStrings.removeErrorMessage,
      );
      cmd.clearResult();
    }
  }

  void _submit() {
    if (_viewModel.saveCommand.running || !_viewModel.validate()) return;
    if (!_viewModel.dirty) {
      Navigator.of(context).pop(false);
      return;
    }
    _viewModel.saveCommand.execute();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, _viewModel.saveCommand]),
      builder: (context, _) {
        final vm = _viewModel;
        return AppBottomModal(
          title: BudgetStrings.itemDetailTitle,
          buttonLabel: '',
          onButtonPressed: () {},
          buttonVisible: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BudgetItemQuantityReadOnlyField(
                  label: BudgetStrings.itemLabelDescription,
                  value: vm.description,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BudgetItemQuantityReadOnlyField(
                        label: BudgetStrings.itemLabelCategory,
                        value: vm.category,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BudgetItemQuantityReadOnlyField(
                        label: BudgetStrings.itemLabelMeasure,
                        value: vm.measure.isEmpty ? '-' : vm.measure,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BudgetItemQuantityReadOnlyField(
                  label: BudgetStrings.itemLabelPrice,
                  value: vm.price,
                ),
                const SizedBox(height: 20),
                BudgetItemQuantityInput(
                  label: BudgetStrings.itemLabelQuantity,
                  controller: vm.quantityController,
                  measure: vm.measure,
                  errorText: vm.quantityError,
                  onChanged: vm.onQuantityChanged,
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      BudgetStrings.itemLabelTotal,
                      style: GoogleFonts.heebo(
                        color: modalLabelColor,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      vm.total,
                      style: GoogleFonts.heebo(
                        color: AppBottomModal.grayColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppFormSaveButton(
                  label: BudgetStrings.itemSaveQuantity,
                  highlighted: vm.dirty,
                  loading: vm.saveCommand.running,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
