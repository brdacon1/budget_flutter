import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as UserInfo;
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/common/widgets/modals/confirm_bottom_modal_widget.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/via_cep_service.dart' as CEP;

FirebaseFirestore firestore = FirebaseFirestore.instance;

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
  CustomerInfo orcamento = CustomerInfo();
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

  void init() {
    try {
      Orcamento.ID = item.id;
      Orcamento.DATA = item.data;
      Orcamento.RUA = item.street;
      Orcamento.GERADO = item.generated;
      Orcamento.BAIRRO = item.neighborhood;
      Orcamento.CITY = item.city;
      Orcamento.CEP = item.zip;
      Orcamento.EMAIL = item.email;
      Orcamento.ENDERECO = item.address;
      Orcamento.FONE = item.phone;
      Orcamento.NOMECLIENTE = item.customerName;
      Orcamento.NOMEEMPRESA = item.companyName;
      Orcamento.STATUS = item.status;
      Orcamento.VALORTOTAL = item.totalValue;

      if (item.id.toString() != '') {
        nameButton = 'Atualizar';
        titlePage = 'Editar orçamento';
        titleBox = 'Clique para editar';
        fieldVisible = true;
      } else {
        nameButton = 'Continuar';
        titlePage = 'Criar orçamento';
        titleBox = 'Clique para inserir';
        fieldVisible = false;
      }
      nameController.text = item.customerName.toString();
      dataController.text = item.data.toString();
      idController.text = item.id.toString();

      if (item.street.toString() != 'null') {
        ruaController.text = item.street.toString();
      } else {
        ruaController.text = '';
      }
      if (item.city.toString() != 'null') {
        cityController.text = item.city.toString();
      } else {
        cityController.text = '';
      }
      if (item.phone.toString() != 'null') {
        phoneController.text = maskFormatter.maskText(item.phone.toString());
      } else {
        phoneController.text = '';
      }
      if (item.neighborhood.toString() != 'null') {
        bairroController.text = item.neighborhood.toString();
      } else {
        bairroController.text = '';
      }
      if (item.status.toString() != 'null') {
        statusController.text = item.status.toString();
      } else {
        statusController.text = '';
      }
      if (item.zip.toString() != 'null') {
        cepController.text = maskCep.maskText(item.zip.toString());
      } else {
        cepController.text = '';
      }
      notifyListeners();
    } catch (e) {}
  }

  Future<void> saveBudget(CustomerInfo orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(orcamento.id)
        .set({
      'ID': orcamento.id,
      'DATA': orcamento.data,
      'RUA': orcamento.street,
      'GERADO': orcamento.generated,
      'BAIRRO': orcamento.neighborhood,
      'CITY': orcamento.city,
      'EMAIL': orcamento.email,
      'ENDERECO': orcamento.address,
      'FONE': orcamento.phone,
      'NOMECLIENTE': orcamento.customerName,
      'NOMEEMPRESA': orcamento.companyName,
      'STATUS': orcamento.status,
      'CEP': orcamento.zip,
      'VALORTOTAL': orcamento.totalValue
    }).then((value) async {}).then((value) {
      Orcamento.IDORCAMENTO = orcamento.id;
      Orcamento.VALORTOTAL = orcamento.totalValue ?? 0;
    });
  }

  Future<void> updateItensDADOS(CustomerInfo orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(item.id)
        .update({
      'ID': orcamento.id,
      'DATA': orcamento.data,
      'RUA': orcamento.street,
      'GERADO': orcamento.generated,
      'BAIRRO': orcamento.neighborhood,
      'CITY': orcamento.city,
      'EMAIL': orcamento.email,
      'ENDERECO': orcamento.address,
      'FONE': orcamento.phone,
      'NOMECLIENTE': orcamento.customerName,
      'NOMEEMPRESA': orcamento.companyName,
      'STATUS': orcamento.status,
      'CEP': orcamento.zip,
      'VALORTOTAL': orcamento.totalValue
    }).then((value) async {}).then((value) {});
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
    var findAdress = CEP.ViaCepService();
    if (value.length == 9) {
      var adress = await findAdress.getAdress(value);
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
    int index = 0;
    String? nome;
    String? tel;
    await FlutterContactPicker.pickFullContact().then((value) {
      final FullContact contact = value;
      contact.phones.forEach((result) {
        if (index == 0) {
          nome = contact.name?.nickName;
          tel = result.number;
          tel = tel?.replaceAll('+55', '');
          tel = tel?.replaceAll('+', '');
          nameController.text = nome!;
          phoneController.text = maskFormatter.maskText(tel!);
          notifyListeners();
        }
        index++;
      });
    });
  }

  Future<void> eventSave(BuildContext context, double we) async {
    if (nameButton == "Atualizar") {
      orcamento.totalValue = item.totalValue;
      orcamento.id = item.id;
      orcamento.data = item.data;
      orcamento.email = item.email;
      orcamento.address = item.address;
      orcamento.generated = item.generated;
      orcamento.companyName = item.companyName;
      orcamento.customerName = nameController.text;
      orcamento.phone = phoneController.text;
      orcamento.status = statusController.text;
      orcamento.zip = cepController.text;
      orcamento.street = ruaController.text;
      orcamento.city = cityController.text;
      orcamento.neighborhood = bairroController.text;
      updateItensDADOS(orcamento).then((value) async {
        item.totalValue = orcamento.totalValue;
        item.id = orcamento.id;
        item.data = orcamento.data;
        item.email = orcamento.email;
        item.address = orcamento.address;
        item.generated = orcamento.generated;
        item.companyName = orcamento.companyName;
        item.customerName = nameController.text;
        item.phone = phoneController.text;
        item.status = statusController.text;
        item.zip = cepController.text;
        item.street = ruaController.text;
        item.city = cityController.text;
        item.neighborhood = bairroController.text;
        notifyListeners();
        if (context.mounted) {
          await displayAlert.notification(
            context,
            'Feito!',
            'Dados do orçamento atualizado com sucesso!',
          );
        }
      });
    } else if (nameButton == "Continuar") {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);
      orcamento.totalValue = 0;
      orcamento.email = item.email;
      orcamento.address = item.address;
      orcamento.generated = item.generated;
      orcamento.companyName = item.companyName;
      orcamento.id = DateTime.now().millisecondsSinceEpoch.toString();
      orcamento.data = formatted;
      orcamento.customerName = nameController.text;
      orcamento.phone = phoneController.text;
      orcamento.status = statusController.text;
      orcamento.zip = cepController.text;
      orcamento.street = ruaController.text;
      orcamento.city = cityController.text;
      orcamento.neighborhood = bairroController.text;
      saveBudget(orcamento).then((value) async {
        item.totalValue = orcamento.totalValue;
        item.id = orcamento.id;
        item.data = orcamento.data;
        item.email = orcamento.email;
        item.address = orcamento.address;
        item.generated = orcamento.generated;
        item.companyName = orcamento.companyName;
        item.customerName = nameController.text;
        item.phone = phoneController.text;
        item.status = statusController.text;
        item.zip = orcamento.zip;
        item.street = ruaController.text;
        item.city = cityController.text;
        item.neighborhood = bairroController.text;
        Orcamento.ID = item.id;
        Orcamento.DATA = item.data;
        Orcamento.RUA = item.street;
        Orcamento.GERADO = item.generated;
        Orcamento.BAIRRO = item.neighborhood;
        Orcamento.CITY = item.city;
        Orcamento.CEP = item.zip;
        Orcamento.EMAIL = item.email;
        Orcamento.ENDERECO = item.address;
        Orcamento.FONE = item.phone;
        Orcamento.NOMECLIENTE = item.customerName;
        Orcamento.NOMEEMPRESA = item.companyName;
        Orcamento.STATUS = item.status;
        Orcamento.VALORTOTAL = item.totalValue;
        nameButton = 'Atualizar';
        titlePage = 'Editar orçamento';
        titleBox = 'Clique para editar';
        fieldVisible = true;
        dataController.text = orcamento.data.toString();
        idController.text = orcamento.id.toString();
        notifyListeners();
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
              message:
                  'Gostaria de salvar o telefone em sua lista de contatos?',
            );
            if (saveContact) {
              UserInfo.Contact newContact = UserInfo.Contact()
                ..name = Name(first: orcamento.customerName.toString())
                ..phones = [
                  Phone(orcamento.phone.toString()),
                  Phone(orcamento.phone.toString(), label: PhoneLabel.work)
                ];
              await UserInfo.FlutterContacts.insertContact(newContact);
            }
          }
        }
      });
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
