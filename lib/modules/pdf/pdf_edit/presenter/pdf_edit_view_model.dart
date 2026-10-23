import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/modules/core/services/data/service/http_request.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/core/services/data/service/via_cep_service.dart' as CEP;
import 'package:oflite/modules/core/services/data/service/display_alert.dart';
import 'package:oflite/modules/core/services/data/service/loading_event.dart';


class PdfEditViewModel extends ChangeNotifier {
  final Color enabledtxt = Colors.white;
  final Color deaible = Colors.white;

  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();

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

  PdfEditViewModel();

  Future<void> inicialData() async {
    loading = true;
    hasError = false;
    notifyListeners();

    try {
      owner = await db.getInformationEnterprise();

      String? token;
      if (UID.googleAuth!) {
        token = await db.authGoogle();
      } else {
        final auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: UID.email!.trim(),
          password: UID.password!.trim(),
        );
        token = await auth.user?.getIdToken();
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
    loadingEvent.alertLoading(context);
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

      await db.savePDF(localOwner);
      owner = localOwner;

      loadingEvent.closeLoading(context);
      await displayAlert.notification(
          context, "Feito!", "Dados do PDF atualizados com sucesso!");
    } catch (_) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(
          context, "Erro!", "Problemas ao atualizar os dados do PDF");
    }
  }

  Future<void> lookupCep(String value) async {
    if (value.length != 9) return;
    try {
      final findAdress = CEP.ViaCepService();
      final adress = await findAdress.getAdress(value);
      ruaText.text = adress.logradouro?.toUpperCase() ?? '';
      cityText.text = adress.localidade?.toUpperCase() ?? '';
      bairroText.text = adress.bairro?.toUpperCase() ?? '';
      notifyListeners();
    } catch (_) {
    }
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
