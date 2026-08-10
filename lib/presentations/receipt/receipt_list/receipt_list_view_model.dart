import 'package:flutter/material.dart';
import 'package:oflite/common/strings/receipt_strings.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/receipt.dart';
import 'package:oflite/presentations/receipt/receipt_tab/receipt_tab_view.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/http_request.dart';
import 'package:oflite/services/loading_event.dart';

/// Gerenciamento de estado da tela de **lista de recibos**.
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Detém a lista de recibos ([foundPayment]) vindos do Firebase
/// (`ORCAMENTOS/{IDORCAMENTO}/RECIBOS` via [HttpRequest.getListRecived]) e a
/// regra de exclusão/abertura/criação.
///
/// **Regra de negócio preservada 1:1 da View original** (apenas relocada para
/// o VM, sem alterar o fluxo):
/// - [inicialData]: carrega `getListRecived()` e notifica.
/// - [deleteReceipt]: abre loading, chama `deleteRecived`, fecha loading,
///   notifica sucesso e recarrega; em erro, fecha loading e notifica erro.
/// - [openReceipt]: navega para [ReceiptTabView] com o recibo selecionado e
///   recarrega ao voltar.
/// - [addReceipt]: cria um `Receipt` vazio (`DESCRICAO = 'null'`), define
///   `budget.IDRECIBO` com um timestamp, navega para [ReceiptTabView] e
///   recarrega ao voltar.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Não guarda `BuildContext` como campo (chega por parâmetro nos métodos).
/// - Erros tratados via `DisplayAlert`; operação longa envolta em
///   `LoadingEvent` (abre/fecha loading).
/// - Após navegação, chama `inicialData()` para sincronizar.
class ReceiptListViewModel extends ChangeNotifier {
  // --- Dependências / Services ---
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  // --- Dados de entrada (imutáveis) ---
  final CustomerInfo item;

  // --- Estado da lista ---
  List<Receipt> foundPayment = <Receipt>[];

  ReceiptListViewModel({required this.item});

  /// Carrega os recibos do Firebase e notifica a reconstrução.
  Future<void> inicialData() async {
    foundPayment = await db.getListRecived();
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  /// Exclui o recibo no índice [index]. Preserva o fluxo original: loading →
  /// `deleteRecived` → fecha loading → notifica sucesso → recarrega; em erro,
  /// fecha loading e notifica erro.
  Future<void> deleteReceipt(BuildContext context, int index) async {
    try {
      loadingEvent.alertLoading(context);
      await db.deleteRecived(foundPayment[index]);
      loadingEvent.closeLoading(context);
      await displayAlert.notificationNotCloseScreen(
          context, ReceiptStrings.doneTitle, ReceiptStrings.deleteSuccess);
      await inicialData();
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, ReceiptStrings.errorTitle, ReceiptStrings.deleteError);
    }
  }

  /// Abre o recibo no índice [index] na tela de abas e recarrega ao voltar.
  Future<void> openReceipt(BuildContext context, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptTabView(
          item: item,
          receipt: foundPayment[index],
        ),
      ),
    );
    await inicialData();
  }

  /// Cria um novo recibo: instancia um `Receipt` vazio (`DESCRICAO = 'null'`),
  /// define `budget.IDRECIBO` com timestamp, abre a tela de abas e recarrega
  /// ao voltar.
  Future<void> addReceipt(BuildContext context) async {
    final Receipt itens = Receipt(
      data: '',
      id: '',
      descricao: 'null',
      valorTotal: 0,
    );
    budget.IDRECIBO = DateTime.now().millisecondsSinceEpoch.toString();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptTabView(item: item, receipt: itens),
      ),
    );
    await inicialData();
  }
}
