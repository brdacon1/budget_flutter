import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as UID;
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum Gender {
  fullname,
  email,
  phone,
  site,
  cpf,
  cep,
  rua,
  data,
  city,
  bairro,
}

class PdfEditViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final UserRepository _userRepository;
  final DisplayAlertRepository _displayAlert;
  final LoadingEventRepository _loadingEvent;

  final Color enabledtxt = Colors.white;
  final Color deaible = Colors.white;

  OwnerPdf owner = OwnerPdf();
  Uint8List? fileContent;
  bool loading = false;
  bool hasError = false;
  Gender? selected;

  final TextEditingController nameText = TextEditingController();
  final TextEditingController phoneText = TextEditingController();
  final TextEditingController emailText = TextEditingController();
  final TextEditingController cpfText = TextEditingController();
  final TextEditingController cepText = TextEditingController();
  final TextEditingController ruaText = TextEditingController();
  final TextEditingController cityText = TextEditingController();
  final TextEditingController bairroText = TextEditingController();

  final MaskTextInputFormatter maskPhone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  final MaskTextInputFormatter maskCnpj = MaskTextInputFormatter(
    mask: '##.###.###/0001-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  final MaskTextInputFormatter maskCep = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  PdfEditViewModel({
    PdfRepository? pdfRepository,
    UserRepository? userRepository,
    DisplayAlertRepository? displayAlertRepository,
    LoadingEventRepository? loadingEventRepository,
  })  : _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
        _userRepository = userRepository ?? getIt<UserRepository>(),
        _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>(),
        _loadingEvent = loadingEventRepository ?? getIt<LoadingEventRepository>();

  Future<void> inicialData() async {
    loading = true;
    hasError = false;
    notifyListeners();

    try {
      final result = await _pdfRepository.fetchInformationEnterprise();
      if (result is Ok<OwnerPdf>) {
        owner = result.value;
      }

      String? token;
      final tokenResult = await _userRepository.getIdToken();
      if (tokenResult is Ok<String>) {
        token = tokenResult.value;
      }
      if (token == 'NOT_AUTH' || token == null) {
        if (UID.googleAuth != true) {
          final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: UID.email!.trim(),
            password: UID.password!.trim(),
          );
          token = await auth.user?.getIdToken();
        }
      }

      _syncFormFromOwner();

      final endpointUrl =
          'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=${owner.fotoId}';
      final response = await http.get(
        Uri.parse(endpointUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json;odata=verbose',
        },
      );

      if (response.statusCode == 200 &&
          response.headers["content-type"]?.startsWith("image/") == true) {
        fileContent = response.bodyBytes;
      } else {
        fileContent = null;
      }
    } catch (_) {
      hasError = true;
      fileContent = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _syncFormFromOwner() {
    nameText.text = owner.empresa ?? '';
    phoneText.text = owner.fone ?? '';
    emailText.text = owner.email ?? '';
    cpfText.text = owner.cnpj ?? '';
    cepText.text = owner.cep ?? '';
    ruaText.text = owner.rua ?? '';
    cityText.text = owner.city ?? '';
    bairroText.text = owner.bairro ?? '';
  }

  Future<void> save(BuildContext context) async {
    _loadingEvent.alertLoading(context);
    try {
      final localOwner = OwnerPdf()
        ..bairro = bairroText.text
        ..fotoId = owner.fotoId
        ..city = cityText.text
        ..rua = ruaText.text
        ..cep = cepText.text
        ..email = emailText.text
        ..fone = phoneText.text
        ..cnpj = cpfText.text
        ..empresa = nameText.text
        ..logoName = owner.logoName;

      await _pdfRepository.saveInformationEnterprise(localOwner);
      owner = localOwner;

      _loadingEvent.closeLoading(context);
      await _displayAlert.notification(
          context, "Feito!", "Dados do PDF atualizados com sucesso!");
    } catch (_) {
      _loadingEvent.closeLoading(context);
      await _displayAlert.notificationError(
          context, "Erro!", "Problemas ao atualizar os dados do PDF");
    }
  }

  Future<void> lookupCep(String value) async {
    if (value.length != 9) return;
    try {
      final findAdress = getIt<CepRepository>();
      final adress = await findAdress.getAddress(value);
      ruaText.text = adress.logradouro?.toUpperCase() ?? '';
      cityText.text = adress.localidade?.toUpperCase() ?? '';
      bairroText.text = adress.bairro?.toUpperCase() ?? '';
      notifyListeners();
    } catch (_) {}
  }

  void selectField(Gender field) {
    selected = field;
    notifyListeners();
  }

  Future<void> editLogo(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditView(owner: owner, title: 'Editar Logo'),
      ),
    );
    await inicialData();
  }

  Future<void> openSubscription(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionView()),
    );
    await inicialData();
  }

  @override
  void dispose() {
    nameText.dispose();
    phoneText.dispose();
    emailText.dispose();
    cpfText.dispose();
    cepText.dispose();
    ruaText.dispose();
    cityText.dispose();
    bairroText.dispose();
    super.dispose();
  }
}
