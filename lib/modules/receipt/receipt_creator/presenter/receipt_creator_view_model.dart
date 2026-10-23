import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/shared/common/enums/receipt_field_enum.dart';
import 'package:oflite/shared/common/strings/receipt_strings.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';

/// Gerenciamento de estado da tela de criação/edição de recibo.
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Detém os controllers dos campos (`descricaoText`, `idText`, `dataText`),
/// o estado de qual campo está focado ([selectedField]), se é edição ou
/// criação ([fieldVisible], [nameButton], [titlePage]) e a regra de
/// persistência (Firebase `RECIBOS` via [HttpRequest.savedRecived]).
///
/// Usa o model canônico [Receipt] (`fromJson`/`toJson`/`copyWith`, campos
/// `final`) — ver seção 10 do SDD. Como o `Receipt` agora é **imutável**, a
/// propagação do recibo recém-criado para as abas irmãs (Pagamentos/PDF, que
/// precisam do novo `ID`/`DATA`) é feita via callback [onReceiptCreated] para
/// o [ReceiptTabViewModel], em vez de mutar o objeto compartilhado.
///
/// **Regra de negócio preservada 1:1 da View original** (apenas relocada para
/// o VM, sem alterar o fluxo):
/// - `DESCRICAO` diferente de `'null'` → edição (`ATUALIZAR` / "Editar
///   recibo"), exibindo número e data; caso contrário → criação (`SALVAR` /
///   "Criar recibo"), com número e data ocultos.
/// - Ao **salvar** (criação): gera `ID` a partir de
///   `DateTime.now().millisecondsSinceEpoch`, formata a data atual
///   (`dd/MM/yyyy`), `VALORTOTAL = 0`, persiste, propaga o novo recibo às
///   abas irmãs via [onReceiptCreated] e passa a exibir número e data —
///   **sem** trocar o rótulo do botão (comportamento original mantido).
/// - Ao **atualizar** (edição): reaproveita o `id`/`data`/`valorTotal` do
///   [receipt] recebido (via `copyWith`), persiste e mantém o estado.
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Não guarda `BuildContext` como campo (chega por parâmetro em [save]).
/// - Erros tratados via `DisplayAlert`; operação longa envolta em
///   `LoadingEvent` (abre/fecha loading).
/// - Controllers criados no VM e descartados em `dispose`.
/// - Sem mutação direta de campos do model — usa `copyWith`.
class ReceiptCreatorViewModel extends ChangeNotifier {
  // --- Dependências / Services ---
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();

  // --- Item recebido (imutável; lê id/data/valorTotal no modo edição) ---
  final Receipt receipt;

  // --- Propagação do recibo criado para as abas irmãs ---
  final ValueChanged<Receipt>? onReceiptCreated;

  // --- Controllers dos campos ---
  final TextEditingController descricaoText = TextEditingController();
  final TextEditingController idText = TextEditingController();
  final TextEditingController dataText = TextEditingController();

  // --- Estado visual reativo ---
  ReceiptFieldType? selectedField;
  late bool fieldVisible;
  late String nameButton;
  late String titlePage;

  ReceiptCreatorViewModel({
    required this.receipt,
    this.onReceiptCreated,
  }) {
    _initFromReceipt();
  }

  /// Popula os controllers e o estado a partir do [receipt] recebido,
  /// espelhando o antigo `initState` da View. `DESCRICAO` igual a `'null'`
  /// indica criação; caso contrário, edição.
  void _initFromReceipt() {
    if (receipt.descricao.toString() != 'null') {
      nameButton = ReceiptStrings.updateButton;
      titlePage = ReceiptStrings.editTitle;
      descricaoText.text = receipt.descricao!;
      idText.text = receipt.id!;
      dataText.text = receipt.data!;
      fieldVisible = true;
    } else {
      nameButton = ReceiptStrings.saveButton;
      titlePage = ReceiptStrings.createTitle;
      descricaoText.text = '';
      idText.text = '';
      dataText.text = '';
      fieldVisible = false;
    }
  }

  /// Subtítulo do card de formulário ("Clique para editar/criar recibo"),
  /// derivado do modo atual — espelha o `"Clique para ${titlePage.toLowerCase()}"`
  /// original, agora centralizado em [ReceiptStrings].
  String get formSubtitle =>
      fieldVisible && nameButton == ReceiptStrings.updateButton
          ? ReceiptStrings.formCardSubtitleEdit
          : ReceiptStrings.formCardSubtitleCreate;

  /// Registra a interação com um campo (destaque do campo focado).
  void selectField(ReceiptFieldType field) {
    selectedField = field;
    notifyListeners();
  }

  /// Persiste o recibo (criação ou atualização). Recebe `BuildContext` apenas
  /// para UI (loading/alertas) — não o guarda como campo. Preserva o fluxo
  /// original: criação gera novo `ID`/`DATA`, persiste, propaga às abas irmãs
  /// via [onReceiptCreated] e exibe número/data; atualização reaproveita os
  /// dados do [receipt] (via `copyWith`).
  Future<void> save(BuildContext context) async {
    loadingEvent.alertLoading(context);

    if (nameButton == ReceiptStrings.saveButton) {
      // --- Criação ---
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      final Receipt novo = Receipt(
        descricao: descricaoText.text,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        data: formatted,
        valorTotal: 0,
      );

      await db.savedRecived(novo);
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      await displayAlert.notificationNotCloseScreen(
          context, ReceiptStrings.doneTitle, ReceiptStrings.createSuccess);

      // Propaga o recibo recém-criado às abas irmãs (Pagamentos/PDF).
      onReceiptCreated?.call(novo);

      // Atualiza os controllers para exibir o recibo criado (comportamento
      // original: passa a mostrar número e data).
      dataText.text = novo.data!;
      descricaoText.text = novo.descricao!;
      idText.text = novo.id!;
      fieldVisible = true;
      notifyListeners();
      return;
    }

    if (nameButton == ReceiptStrings.updateButton && fieldVisible) {
      // --- Atualização ---
      final Receipt atualizado =
          receipt.copyWith(descricao: descricaoText.text);

      await db.savedRecived(atualizado);
      if (!context.mounted) return;
      loadingEvent.closeLoading(context);
      await displayAlert.notificationNotCloseScreen(
          context, ReceiptStrings.doneTitle, ReceiptStrings.updateSuccess);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    descricaoText.dispose();
    idText.dispose();
    dataText.dispose();
    super.dispose();
  }
}
