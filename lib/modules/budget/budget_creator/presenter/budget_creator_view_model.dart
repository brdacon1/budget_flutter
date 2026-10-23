import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as UserInfo;
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/shared/common/widgets/modals/confirm_bottom_modal_widget.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/shared/models/global_uid_user.dart' as UID;
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/via_cep_service.dart' as CEP;

enum Gender {
  fullname,
  Email,
  phone,
  cep,
  rua,
  data,
  city,
  id,
  bairro,
  status,
}

class BudgetCreatorViewModel extends ChangeNotifier {
  final CustomerInfo item;
  final DisplayAlert displayAlert = DisplayAlert();

  BudgetCreatorViewModel({required this.item});

  final nameNode = FocusNode();
  final phoneNode = FocusNode();
  final cepNode = FocusNode();
  final ruaNode = FocusNode();
  final cityNode = FocusNode();
  final bairroNode = FocusNode();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  String? titleBox;
  bool fieldVisible = false;
  bool fieldFone = true;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final dataController = TextEditingController();
  final idController = TextEditingController();
  final cepController = TextEditingController();
  final ruaController = TextEditingController();
  final cityController = TextEditingController();
  final bairroController = TextEditingController();
  final statusController = TextEditingController();

  var maskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  var maskCep = MaskTextInputFormatter(
      mask: '#####-###',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  var maskDate = MaskTextInputFormatter(
      mask: '',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  final GlobalKey<ExpansionTileCardState> cardA = GlobalKey<ExpansionTileCardState>();

  // ------------------------------------------------------------------
  // Estado de UI derivado do `item` recebido (novo x edição).
  // ------------------------------------------------------------------

  bool get _isEditing => (item.id ?? '').isNotEmpty;

  void _setupUiState() {
    final editing = _isEditing;
    nameButton = editing ? 'Atualizar' : 'Continuar';
    titlePage = editing ? 'Editar orçamento' : 'Criar orçamento';
    titleBox = editing ? 'Clique para editar' : 'Clique para inserir';
    fieldVisible = editing;
  }

  /// Preenche um controller com texto opcional, tratando `null`/`'null'`.
  void _setNullableController(TextEditingController controller, String? value) {
    controller.text = (value == null || value == 'null') ? '' : value;
  }

  void _fillControllers() {
    nameController.text = item.customerName ?? '';
    dataController.text = item.data ?? '';
    idController.text = item.id ?? '';
    _setNullableController(ruaController, item.street);
    _setNullableController(cityController, item.city);
    _setNullableController(bairroController, item.neighborhood);
    _setNullableController(statusController, item.status);
    phoneController.text =
        (item.phone == null) ? '' : maskFormatter.maskText(item.phone.toString());
    cepController.text =
        (item.zip == null) ? '' : maskCep.maskText(item.zip.toString());
  }

  // ------------------------------------------------------------------
  // Propagação de estado (item compartilhado + globals).
  // A mutação in-place do `item` é intencional: ela reflete o orçamento
  // salvo de volta para a tela pai/abas irmãs que seguram a mesma referência.
  // ------------------------------------------------------------------

  void _applyToItem(CustomerInfo source) {
    item
      ..id = source.id
      ..data = source.data
      ..email = source.email
      ..address = source.address
      ..generated = source.generated
      ..companyName = source.companyName
      ..customerName = source.customerName
      ..phone = source.phone
      ..status = source.status
      ..zip = source.zip
      ..street = source.street
      ..city = source.city
      ..neighborhood = source.neighborhood
      ..totalValue = source.totalValue;
  }

  void _applyToGlobals(CustomerInfo source) {
    Orcamento.ID = source.id;
    Orcamento.DATA = source.data;
    Orcamento.RUA = source.street;
    Orcamento.GERADO = source.generated;
    Orcamento.BAIRRO = source.neighborhood;
    Orcamento.CITY = source.city;
    Orcamento.CEP = source.zip;
    Orcamento.EMAIL = source.email;
    Orcamento.ENDERECO = source.address;
    Orcamento.FONE = source.phone;
    Orcamento.NOMECLIENTE = source.customerName;
    Orcamento.NOMEEMPRESA = source.companyName;
    Orcamento.STATUS = source.status;
    Orcamento.VALORTOTAL = source.totalValue;
  }

  void _enterEditMode(CustomerInfo budget) {
    nameButton = 'Atualizar';
    titlePage = 'Editar orçamento';
    titleBox = 'Clique para editar';
    fieldVisible = true;
    dataController.text = budget.data ?? '';
    idController.text = budget.id ?? '';
  }

  /// Monta o orçamento a partir do `item` + campos editáveis dos controllers.
  /// Em edição mantém id/data/total; na criação gera novo id/data e zera o total.
  CustomerInfo _buildBudget(bool isUpdate, String formattedDate) {
    return CustomerInfo(
      id: isUpdate ? item.id : DateTime.now().millisecondsSinceEpoch.toString(),
      data: isUpdate ? item.data : formattedDate,
      totalValue: isUpdate ? item.totalValue : 0,
      email: item.email,
      address: item.address,
      generated: item.generated,
      companyName: item.companyName,
      customerName: nameController.text,
      phone: phoneController.text,
      status: statusController.text,
      zip: cepController.text,
      street: ruaController.text,
      city: cityController.text,
      neighborhood: bairroController.text,
    );
  }

  // ------------------------------------------------------------------
  // Ações
  // ------------------------------------------------------------------

  void init() {
    try {
      _applyToGlobals(item);
      _setupUiState();
      _fillControllers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveBudget(CustomerInfo budget) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(budget.id)
        .set({
      'ID': budget.id,
      'DATA': budget.data,
      'RUA': budget.street,
      'GERADO': budget.generated,
      'BAIRRO': budget.neighborhood,
      'CITY': budget.city,
      'EMAIL': budget.email,
      'ENDERECO': budget.address,
      'FONE': budget.phone,
      'NOMECLIENTE': budget.customerName,
      'NOMEEMPRESA': budget.companyName,
      'STATUS': budget.status,
      'CEP': budget.zip,
      'VALORTOTAL': budget.totalValue,
    });
    Orcamento.IDORCAMENTO = budget.id;
    Orcamento.VALORTOTAL = budget.totalValue ?? 0;
  }

  Future<void> updateItensDADOS(CustomerInfo budget) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(item.id)
        .update({
      'ID': budget.id,
      'DATA': budget.data,
      'RUA': budget.street,
      'GERADO': budget.generated,
      'BAIRRO': budget.neighborhood,
      'CITY': budget.city,
      'EMAIL': budget.email,
      'ENDERECO': budget.address,
      'FONE': budget.phone,
      'NOMECLIENTE': budget.customerName,
      'NOMEEMPRESA': budget.companyName,
      'STATUS': budget.status,
      'CEP': budget.zip,
      'VALORTOTAL': budget.totalValue,
    });
  }

  void selectField(Gender field) {
    selected = field;
    notifyListeners();
  }

  void setFieldFone(bool value) {
    fieldFone = value;
    notifyListeners();
  }

  Future<void> onCepChanged(String value) async {
    if (value.length == 9) {
      final adress = await CEP.ViaCepService().getAdress(value);
      ruaController.text = adress.logradouro!.toUpperCase();
      cityController.text = adress.localidade!.toUpperCase();
      bairroController.text = adress.bairro!.toUpperCase();
      notifyListeners();
    }
  }

  void setStatus(String value) {
    statusController.text = value;
    notifyListeners();
  }

  Future<void> pickContact(double we, BuildContext context) async {
    nameNode.requestFocus();
    final confirm = await showConfirmBottomModal(
      context,
      title: 'Lista de contatos',
      message: 'Gostaria de buscar cliente em sua lista de contatos?',
    );
    if (!confirm) {
      fieldFone = false;
      notifyListeners();
      return;
    }
    fieldFone = true;
    notifyListeners();
    await FlutterContactPicker.pickFullContact().then((value) {
      final FullContact contact = value;
      var index = 0;
      String? nome;
      String? tel;
      for (final result in contact.phones) {
        if (index == 0) {
          nome = contact.name?.nickName;
          tel = result.number?.replaceAll('+55', '').replaceAll('+', '');
          nameController.text = nome!;
          phoneController.text = maskFormatter.maskText(tel!);
          notifyListeners();
        }
        index++;
      }
    });
  }

  Future<void> eventSave(BuildContext context, double we) async {
    final isUpdate = nameButton == 'Atualizar';
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final CustomerInfo budget = _buildBudget(isUpdate, formattedDate);

    if (isUpdate) {
      await updateItensDADOS(budget);
    } else {
      await saveBudget(budget);
    }

    // Reflete o orçamento salvo de volta no item compartilhado (tela pai/abas).
    _applyToItem(budget);
    // Na criação, atualiza também os globals e entra em modo de edição.
    if (!isUpdate) {
      _applyToGlobals(budget);
      _enterEditMode(budget);
    }
    notifyListeners();

    // Feedback / fluxo de contato (preserva comportamento original por modo).
    if (isUpdate) {
      if (context.mounted) {
        await displayAlert.notification(
          context,
          'Feito!',
          'Dados do orçamento atualizado com sucesso!',
        );
      }
      return;
    }

    if (await UserInfo.FlutterContacts.requestPermission()) {
      if (context.mounted) {
        await displayAlert.notification(
          context,
          'Feito!',
          'Orçamento criado com sucesso!',
        );
      }
      if (context.mounted) {
        final saveContact = await showConfirmBottomModal(
          context,
          title: 'Salvar contato',
          message: 'Gostaria de salvar o telefone em sua lista de contatos?',
        );
        if (saveContact) {
          final newContact = UserInfo.Contact()
            ..name = Name(first: budget.customerName ?? '')
            ..phones = [
              Phone(budget.phone ?? ''),
              Phone(budget.phone ?? '', label: PhoneLabel.work),
            ];
          await UserInfo.FlutterContacts.insertContact(newContact);
        }
      }
    }
  }

  @override
  void dispose() {
    nameNode.dispose();
    phoneNode.dispose();
    cepNode.dispose();
    ruaNode.dispose();
    cityNode.dispose();
    bairroNode.dispose();
    nameController.dispose();
    phoneController.dispose();
    dataController.dispose();
    idController.dispose();
    cepController.dispose();
    ruaController.dispose();
    cityController.dispose();
    bairroController.dispose();
    statusController.dispose();
    super.dispose();
  }
}
