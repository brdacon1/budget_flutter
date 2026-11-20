import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/components/modals/receipt_list_actions_bottom_modal_widget.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/components/receipt_card.dart';
import 'package:oflite/modules/receipt/presenter/receipt_list/components/receipt_total_bar.dart';
import 'package:oflite/modules/receipt/presenter/receipt_tab/receipt_tab_view.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

import 'receipt_list_view_model.dart';

/// Tela de **lista de recibos**.
///
/// `StatefulWidget` que cria o [ReceiptListViewModel] em `initState` e o
/// descarta em `dispose`. Toda a reconstrução reativa acontece via
/// `AnimatedBuilder(animation: _viewModel, ...)` — **nenhum `setState`**.
///
/// A View apenas compõe a estrutura (header + lista + FAB) e delega as ações
/// (carregar, excluir, abrir, criar) ao ViewModel. Os blocos visuais
/// repetidos vivem em `components/` ([ReceiptListHeader], [ReceiptCard]).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Componentes recebem dados + callbacks, nunca o VM inteiro.
/// - `BuildContext` recebido por parâmetro nos métodos do VM (não guardado).
/// - `RefreshIndicator.onRefresh` aponta para `_viewModel.refresh`.
/// - `ListView.builder` com `itemCount`/`itemBuilder` lendo o VM.
/// - `FloatingActionButton` delega ação ao VM.
class ReceiptListView extends StatefulWidget {
  final CustomerInfo item;

  const ReceiptListView({super.key, required this.item});

  @override
  State<ReceiptListView> createState() => _ReceiptListView();
}

class _ReceiptListView extends State<ReceiptListView> {
  late final ReceiptListViewModel _viewModel;
  final LoadingEventRepository alertDisplayLoading =
      getIt<LoadingEventRepository>();
  final DisplayAlertRepository displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = ReceiptListViewModel(item: widget.item);
    _viewModel.deleteReceiptCommand.addListener(_onDeleteCommandChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _viewModel.deleteReceiptCommand.removeListener(_onDeleteCommandChanged);
    super.dispose();
  }

  Future<void> _onDeleteCommandChanged() async {
    if (_viewModel.deleteReceiptCommand.running) {
      await _openLoad(isOpen: true);
    }

    if (_viewModel.deleteReceiptCommand.error) {
      await _openLoad(isOpen: false);
      await _notification(
        isSuccess: false,
        primaryText: ReceiptPtString.errorTitle,
        message: ReceiptPtString.deleteError,
      );

      await _viewModel.inicialData();
    } else if (_viewModel.deleteReceiptCommand.completed) {
      await _openLoad(isOpen: false);
      await _notification(
        isSuccess: true,
        primaryText: ReceiptPtString.doneTitle,
        message: ReceiptPtString.deleteSuccess,
      );
    }
  }

  Future<void> _notification({
    required bool isSuccess,
    required String primaryText,
    required String message,
  }) async {
    if (context.mounted) {
      if (isSuccess) {
        await displayAlert.notification(context, primaryText, message);
      } else {
        await displayAlert.notificationError(context, primaryText, message);
      }
    }
  }

  Future<void> _openLoad({required bool isOpen}) async {
    if (context.mounted) {
      if (isOpen) {
        await alertDisplayLoading.alertLoading(context);
      } else {
        alertDisplayLoading.closeLoading(context);
      }
    }
  }

  Future<void> _openReceipt(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReceiptTabView(
              item: _viewModel.item,
              receipt: _viewModel.foundPayment[index],
            ),
      ),
    );
    await _viewModel.refresh();
  }

  Future<void> _openActions(int index) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: transparentColor,
      builder:
          (_) => ReceiptListActionsBottomModalWidget(
            item: _viewModel.foundPayment[index],
            moneyConvert: _viewModel.moneyConvert,
            onDelete: () => _viewModel.deleteReceiptCommand.execute(index),
            onOpen: () => _openReceipt(index),
          ),
    );
  }

  Widget _buildListReceipt() {
    if (_viewModel.foundPayment.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Text(
          ReceiptPtString.emptyList,
          style: const TextStyle(fontSize: 14, color: emptyTextColor),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Expanded(
      child: RefreshIndicator(
        color: refreshIndicatorColor,
        backgroundColor: bgColor,
        onRefresh: _viewModel.refresh,
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          itemCount: _viewModel.foundPayment.length,
          itemBuilder: (context, index) {
            return ReceiptCard(
              item: _viewModel.foundPayment[index],
              moneyConvert: _viewModel.moneyConvert,
              onTap: () => _openReceipt(index),
              onMore: () => _openActions(index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return FloatingActionButton.extended(
          heroTag: 'adicionar_comentario',
          onPressed: () => _viewModel.addReceipt(context),
          backgroundColor: buttonColor,
          elevation: 4,
          shape: const StadiumBorder(),
          icon: const Icon(Icons.add, color: blackColor, size: 20),
          label: Text(
            ReceiptPtString.newReceipt,
            style: const TextStyle(
              color: blackColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder:
            (_, __) => ReceiptTotalBar(
              count: _viewModel.foundPayment.length,
              total: _viewModel.totalText,
            ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              AppHeaderSecondTitle(
                titlePage: ReceiptPtString.listTitle,
                secondTitle: ReceiptPtString.listSubtitle,
                onBack: () => Navigator.pop(context, true),
              ),
              _buildListReceipt(),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
