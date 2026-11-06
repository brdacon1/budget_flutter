import 'package:flutter/material.dart';
import 'package:oflite/modules/payment/data/model/payment_customer.dart';
import 'package:oflite/modules/payment/payment_creator/presenter/payment_creator_view_model.dart';
import 'package:oflite/modules/payment/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';

import 'components/payment_creator_field.dart';

/// Modal inferior de criação/edição de pagamento.
///
/// Segue o **padrão de bottom modal** do app, reaproveitando a base visual
/// [AppBottomModal] (header com título + botão fechar, drag handle, botão de
/// ação no rodapé e acompanhamento do teclado). Mantém View + ViewModel — o
/// [PaymentCreatorViewModel] (`extends ChangeNotifier`) detém o estado; a View
/// reage via `AnimatedBuilder` e delega `saveCommand.execute()`.
///
/// Regras seguidas (ver `.pi/PROJECT_STRUCTURE.md`):
/// - `StatefulWidget` que cria o VM em `initState` e o descarta em `dispose`.
/// - Reconstrução via `AnimatedBuilder(animation: _viewModel, ...)` — sem
///   `setState` para mudanças de estado do VM.
/// - Escuta do `Command` via `addListener` para reagir a sucesso/erro.
/// - Componentes (`PaymentCreatorField`) recebem dados + callbacks, nunca o VM
///   inteiro.
/// - Abertura/fechamento do modal fica por conta de quem chama
///   (`showPaymentCreatorBottomModal`), mantendo a navegação desacoplada.
class PaymentCreatorView extends StatefulWidget {
  final PaymentCustomer item;

  const PaymentCreatorView({super.key, required this.item});

  @override
  State<PaymentCreatorView> createState() => _PaymentCreatorViewState();
}

class _PaymentCreatorViewState extends State<PaymentCreatorView> {
  late final PaymentCreatorViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentCreatorViewModel(item: widget.item);
    _viewModel.saveCommand.addListener(_onSaveCommandChanged);
  }

  @override
  void dispose() {
    _viewModel.saveCommand.removeListener(_onSaveCommandChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onSaveCommandChanged() {
    if (!mounted) return;
    final cmd = _viewModel.saveCommand;

    if (cmd.completed) {
      Navigator.pop(context, true);
      return;
    }

    if (cmd.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: ${cmd.result}')),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final saving = _viewModel.saveCommand.running;

        return AppBottomModal(
          title: _viewModel.titlePage ?? '',
          buttonLabel: saving ? 'Aguarde...' : (_viewModel.nameButton ?? ''),
          onButtonPressed: saving
              ? () {}
              : _viewModel.saveCommand.execute,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                PaymentCreatorField(
                  controller: _viewModel.typeText,
                  hintText: PaymentStrings.paymentHint,
                  icon: Icons.list_alt,
                  readOnly: true,
                  onTap: () => _viewModel.selectType(context),
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: AppBottomModal.grayColor,
                  ),
                ),
                const SizedBox(height: 16),
                PaymentCreatorField(
                  controller: _viewModel.controller,
                  hintText: PaymentStrings.priceHint,
                  icon: Icons.price_change_outlined,
                  keyboardType: TextInputType.number,
                  onTap: () => _viewModel.selectField(Gender.precoText),
                ),
                const SizedBox(height: 16),
                PaymentCreatorField(
                  controller: _viewModel.descricaoText,
                  hintText: PaymentStrings.paymentDescriptionHint,
                  icon: Icons.edit_note,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  onTap: () => _viewModel.selectField(Gender.descricaoText),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper que abre o [PaymentCreatorView] como modal bottom sheet.
///
/// Segue o mesmo formato dos demais helpers de modal do app
/// (`showProductPriceCreatorBottomModal`, `showAppBottomModal`):
/// `isScrollControlled` para acompanhar o teclado e fundo transparente
/// (a base [AppBottomModal] desenha o card branco arredondado). Retorna
/// `true` quando o pagamento é salvo/atualizado, para que a tela de origem
/// recarregue a lista.
Future<bool?> showPaymentCreatorBottomModal(
  BuildContext context, {
  required PaymentCustomer item,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PaymentCreatorView(item: item),
  );
}
