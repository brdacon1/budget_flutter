import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/injection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as user_info;

import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum CepLookupState { idle, loading, found, notFound }

class BudgetCreatorViewModel extends ChangeNotifier {
  final BudgetRepository _budgetRepository = getIt<BudgetRepository>();
  final CustomerInfo item;

  BudgetCreatorViewModel({required this.item});

  /// Valores persistidos — fixos (nunca traduzir; só o label muda).
  static const statusOptions = [
    'PENDENTE',
    'APROVADO',
    'REPROVADO',
    'FINALIZADO',
  ];
  static const _defaultStatus = 'PENDENTE';

  String? nameError;
  CepLookupState cepState = CepLookupState.idle;
  String _snapshot = '';

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final cepController = TextEditingController();
  final ruaController = TextEditingController();
  final cityController = TextEditingController();
  final bairroController = TextEditingController();
  final statusController = TextEditingController();

  final nameNode = FocusNode();
  final phoneNode = FocusNode();
  final cepNode = FocusNode();
  final ruaNode = FocusNode();
  final cityNode = FocusNode();
  final bairroNode = FocusNode();

  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final maskCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool get isEditing => (item.id ?? '').isNotEmpty;

  String get titlePage => isEditing ? 'Editar orçamento' : 'Criar orçamento';
  String get nameButton => isEditing ? 'Salvar alterações' : 'Continuar';

  List<TextEditingController> get _editable => [
    nameController,
    phoneController,
    statusController,
    cepController,
    ruaController,
    cityController,
    bairroController,
  ];

  String _currentValues() => _editable.map((c) => c.text).join('|');

  /// Há alterações não salvas? No modo criar o botão fica sempre destacado.
  bool get isDirty => !isEditing || _currentValues() != _snapshot;

  void _takeSnapshot() => _snapshot = _currentValues();

  String _clean(String? value) =>
      (value == null || value == 'null') ? '' : value;

  void _fillControllers() {
    nameController.text = _clean(item.customerName);
    ruaController.text = _clean(item.street);
    cityController.text = _clean(item.city);
    bairroController.text = _clean(item.neighborhood);
    final status = _clean(item.status);
    statusController.text = status.isEmpty ? _defaultStatus : status;
    final phone = _clean(item.phone);
    phoneController.text = phone.isEmpty ? '' : maskFormatter.maskText(phone);
    final zip = _clean(item.zip);
    cepController.text = zip.isEmpty ? '' : maskCep.maskText(zip);
  }

  void _onFieldChanged() {
    if (nameError != null && nameController.text.trim().isNotEmpty) {
      nameError = null;
    }
    notifyListeners();
  }

  void _applyToItem(CustomerInfo source) {
    item
      ..id = source.id
      ..data = source.data
      ..email = source.email
      ..address = source.address
      ..generated = source.generated
      ..customerName = source.customerName
      ..phone = source.phone
      ..status = source.status
      ..zip = source.zip
      ..street = source.street
      ..city = source.city
      ..neighborhood = source.neighborhood
      ..totalValue = source.totalValue;
  }

  CustomerInfo _buildBudget(bool isUpdate, String formattedDate) {
    return CustomerInfo(
      id: isUpdate ? item.id : DateTime.now().millisecondsSinceEpoch.toString(),
      data: isUpdate ? item.data : formattedDate,
      totalValue: isUpdate ? item.totalValue : 0,
      email: item.email,
      address: item.address,
      generated: item.generated,
      customerName: nameController.text.trim(),
      phone: phoneController.text,
      status: statusController.text,
      zip: cepController.text,
      street: ruaController.text,
      city: cityController.text,
      neighborhood: bairroController.text,
    );
  }

  void init() {
    _fillControllers();
    _takeSnapshot();
    for (final c in _editable) {
      c.addListener(_onFieldChanged);
    }
    notifyListeners();
  }

  void setStatus(String value) {
    statusController.text = value;
  }

  Future<void> onCepChanged(String value) async {
    if (value.length != 9) {
      if (cepState != CepLookupState.idle) {
        cepState = CepLookupState.idle;
        notifyListeners();
      }
      return;
    }
    cepState = CepLookupState.loading;
    notifyListeners();
    try {
      final address = await getIt<CepRepository>().getAddress(value);
      final street = address.logradouro ?? '';
      final city = address.localidade ?? '';
      final district = address.bairro ?? '';
      if (street.isEmpty && city.isEmpty) {
        cepState = CepLookupState.notFound;
      } else {
        if (street.isNotEmpty) ruaController.text = street.toUpperCase();
        if (city.isNotEmpty) cityController.text = city.toUpperCase();
        if (district.isNotEmpty) bairroController.text = district.toUpperCase();
        cepState = CepLookupState.found;
      }
    } catch (_) {
      cepState = CepLookupState.notFound;
    }
    notifyListeners();
  }

  /// Ação explícita "Importar da agenda" (§17.3) — sem modal ao focar campo.
  Future<void> pickContact() async {
    final permissionStatus = await user_info.FlutterContacts.permissions
        .request(user_info.PermissionType.read);
    if (permissionStatus != user_info.PermissionStatus.granted &&
        permissionStatus != user_info.PermissionStatus.limited) {
      return;
    }

    final contact = await user_info.FlutterContacts.native.showPicker(
      properties: {
        user_info.ContactProperty.name,
        user_info.ContactProperty.phone,
      },
    );
    if (contact == null) return;

    String name = contact.displayName?.trim() ?? '';
    if (name.isEmpty) {
      name =
          '${contact.name?.first?.trim() ?? ''} ${contact.name?.last?.trim() ?? ''}'
              .trim();
    }
    if (name.isNotEmpty) nameController.text = name;

    final phones = contact.phones;
    if (phones.isNotEmpty) {
      final tel = phones.first.number
          .replaceAll('+55', '')
          .replaceAll(RegExp(r'[^0-9]'), '');
      if (tel.isNotEmpty) phoneController.text = maskFormatter.maskText(tel);
    }
  }

  /// Validação no submit, erro abaixo do campo (§17.4).
  bool validate() {
    if (nameController.text.trim().isEmpty) {
      nameError = 'Informe o nome do cliente';
      notifyListeners();
      nameNode.requestFocus();
      return false;
    }
    return true;
  }

  late final Command0<void> saveBudgetCommand = Command0(_executeSaveBudget);

  Future<Result<void>> _executeSaveBudget() async {
    final isUpdate = isEditing;
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final budget = _buildBudget(isUpdate, formattedDate);

    try {
      if (isUpdate) {
        await _budgetRepository.updateBudget(budget);
      } else {
        await _budgetRepository.saveBudget(budget);
      }
      _applyToItem(budget);
      _takeSnapshot();
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  void dispose() {
    for (final c in _editable) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    nameNode.dispose();
    phoneNode.dispose();
    cepNode.dispose();
    ruaNode.dispose();
    cityNode.dispose();
    bairroNode.dispose();
    super.dispose();
  }
}
