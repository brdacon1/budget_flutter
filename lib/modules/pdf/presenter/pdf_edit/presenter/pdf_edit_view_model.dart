import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/image/presenter/image_edit_view.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/format_document_usecase.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/validate_document_usecase.dart';
import 'package:oflite/modules/pdf/presenter/formatter/document_input_formatter.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/design_pattern/result.dart';

enum Gender { fullname, email, phone, site, cpf, cep, rua, data, city, bairro }

class PdfEditViewModel extends ChangeNotifier {
  final PdfRepository _pdfRepository;
  final UserRepository _userRepository;
  final DisplayAlertRepository _displayAlert;
  final LoadingEventRepository _loadingEvent;
  final ValidateDocumentUsecase _validateDocument;
  final FormatDocumentUsecase _formatDocument;

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
  late final DocumentInputFormatter maskCnpj = DocumentInputFormatter(
    _formatDocument.partial,
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
    ValidateDocumentUsecase? validateDocument,
    FormatDocumentUsecase? formatDocument,
  }) : _validateDocument = validateDocument ?? getIt<ValidateDocumentUsecase>(),
       _formatDocument = formatDocument ?? getIt<FormatDocumentUsecase>(),
       _pdfRepository = pdfRepository ?? getIt<PdfRepository>(),
       _userRepository = userRepository ?? getIt<UserRepository>(),
       _displayAlert =
           displayAlertRepository ?? getIt<DisplayAlertRepository>(),
       _loadingEvent =
           loadingEventRepository ?? getIt<LoadingEventRepository>();

  Future<void> inicialData() async {
    loading = true;
    hasError = false;
    notifyListeners();

    try {
      final result = await _pdfRepository.fetchInformationEnterprise();
      if (result is Ok<OwnerPdf>) {
        owner = result.value;
      }

      _syncFormFromOwner();

      final logo = await _pdfRepository.fetchLogo(owner, requireImage: true);
      switch (logo) {
        case Ok<Uint8List?>(:final value):
          fileContent = value;
        case Error<Uint8List?>():
          hasError = true;
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
    // Documento é opcional nesta tela; se preenchido, precisa ser válido.
    var document = cpfText.text.trim();
    if (document.isNotEmpty) {
      final validation = _validateDocument(document);
      if (!validation.isValid) {
        await _displayAlert.notificationError(
          context,
          "Erro!",
          PdfStrings.documentError(validation.error!),
        );
        return;
      }
      document = _formatDocument(validation.cleaned!, validation.type!);
      cpfText.text = document;
    }
    if (!context.mounted) return;
    _loadingEvent.alertLoading(context);
    try {
      final localOwner =
          OwnerPdf()
            ..bairro = bairroText.text.trim().toUpperCase()
            ..fotoId = owner.fotoId
            ..city = cityText.text.trim().toUpperCase()
            ..rua = ruaText.text.trim().toUpperCase()
            ..cep = cepText.text.trim()
            ..email = emailText.text.trim()
            ..fone = phoneText.text.trim()
            ..cnpj = document
            ..empresa = nameText.text.trim().toUpperCase()
            ..logoName = owner.logoName
            ..pdfLayoutType = owner.pdfLayoutType;

      await _pdfRepository.saveInformationEnterprise(localOwner);
      owner = localOwner;

      _loadingEvent.closeLoading(context);
      await _displayAlert.notification(
        context,
        "Feito!",
        "Dados do PDF atualizados com sucesso!",
      );
    } catch (_) {
      _loadingEvent.closeLoading(context);
      await _displayAlert.notificationError(
        context,
        "Erro!",
        "Problemas ao atualizar os dados do PDF",
      );
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
