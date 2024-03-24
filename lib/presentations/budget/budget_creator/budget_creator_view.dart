import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import '../../../models/customer_info.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/services/via_cep_service.dart' as CEP;
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as UserInfo;
import 'package:oflite/models/global_uid_budget.dart' as Orcamento;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:intl/intl.dart';

import '../../../common/constants/constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
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

TextEditingController _nameText = TextEditingController();
TextEditingController _phoneText = TextEditingController();
TextEditingController _dataText = TextEditingController();
TextEditingController _idText = TextEditingController();
TextEditingController _cepText = TextEditingController();
TextEditingController _ruaText = TextEditingController();
TextEditingController _cityText = TextEditingController();
TextEditingController _bairroText = TextEditingController();
TextEditingController _statusText = TextEditingController();

class BudgetCreatorView extends StatefulWidget {
  final CustomerInfo item;
  const BudgetCreatorView({Key? key, required this.item}) : super(key: key);

  @override
  State<BudgetCreatorView> createState() => _BudgetCreatorView();
}

class _BudgetCreatorView extends State<BudgetCreatorView> {
  BannerAd? _bannerAd;
  final String _adUnitId = 'ca-app-pub-5106035309089315/6550502888';
  final _name = FocusNode();
  final _phone = FocusNode();
  final _cep = FocusNode();
  final _rua = FocusNode();
  final _city = FocusNode();
  final _bairro = FocusNode();
  CustomerInfo orcamento = CustomerInfo();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  String? titleBox;
  bool fieldVisible = false;
  bool fieldFone = true;

  void _loadAd() async {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  var maskFormatter =  MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskCep =  MaskTextInputFormatter(
      mask: '#####-###',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskDate =  MaskTextInputFormatter(
      mask: '',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  final GlobalKey<ExpansionTileCardState> cardA = GlobalKey();

  @override
  initState() {
    super.initState();
    try{
      _loadAd();
      setState(() {
        Orcamento.ID = widget.item.id;
        Orcamento.DATA = widget.item.data;
        Orcamento.RUA = widget.item.street;
        Orcamento.GERADO = widget.item.generated;
        Orcamento.BAIRRO = widget.item.neighborhood;
        Orcamento.CITY = widget.item.city;
        Orcamento.CEP = widget.item.zip;
        Orcamento.EMAIL = widget.item.email;
        Orcamento.ENDERECO = widget.item.address;
        Orcamento.FONE = widget.item.phone;
        Orcamento.NOMECLIENTE = widget.item.customerName;
        Orcamento.NOMEEMPRESA = widget.item.companyName;
        Orcamento.STATUS = widget.item.status;
        Orcamento.VALORTOTAL = widget.item.totalValue;

        if(widget.item.id.toString() != '')
        {
          nameButton = 'Atualizar';
          titlePage = 'Editar orçamento';
          titleBox = 'Clique para editar';
          fieldVisible = true;
        }
        else
        {
          nameButton = 'Continuar';
          titlePage = 'Criar orçamento';
          titleBox = 'Clique para inserir';
          fieldVisible = false;
        }
        _nameText.text = widget.item.customerName.toString();
        _dataText.text = widget.item.data.toString();
        _idText.text = widget.item.id.toString();

        if(widget.item.street.toString() != 'null')
        {
          _ruaText.text = widget.item.street.toString();
        }
        else
        {
          _ruaText.text = '';
        }
        if(widget.item.city.toString() != 'null')
        {
          _cityText.text = widget.item.city.toString();
        }
        else
        {
          _cityText.text = '';
        }
        if(widget.item.phone.toString() != 'null')
        {
          _phoneText.text = maskFormatter.maskText(widget.item.phone.toString());

        }
        else
        {
          _phoneText.text = '';
        }
        if(widget.item.neighborhood.toString() != 'null')
        {
          _bairroText.text = widget.item.neighborhood.toString();
        }
        else
        {
          _bairroText.text = '';
        }
        if(widget.item.status.toString() != 'null')
        {
          _statusText.text = widget.item.status.toString();
        }
        else
        {
          _statusText.text = '';
        }
        if(widget.item.zip.toString() != 'null')
        {
          _cepText.text = maskCep.maskText(widget.item.zip.toString());
        }
        else
        {
          _cepText.text = '';
        }
      });
    }
    catch (e) {}
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future <void> saveBudget(CustomerInfo orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(orcamento.id)
        .set({
      'ID': orcamento.id,
      'DATA' : orcamento.data,
      'RUA' : orcamento.street,
      'GERADO' : orcamento.generated,
      'BAIRRO' : orcamento.neighborhood,
      'CITY' : orcamento.city,
      'EMAIL' : orcamento.email,
      'ENDERECO' : orcamento.address,
      'FONE' : orcamento.phone,
      'NOMECLIENTE' : orcamento.customerName,
      'NOMEEMPRESA' : orcamento.companyName,
      'STATUS' : orcamento.status,
      'CEP' : orcamento.zip,
      'VALORTOTAL': orcamento.totalValue}).then((value) async {
    }).then((value) {
      Orcamento.IDORCAMENTO = orcamento.id;
      Orcamento.VALORTOTAL = orcamento.totalValue ?? 0;
    });
  }

  Future <void> UpdateItensDADOS(CustomerInfo orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .doc(widget.item.id)
        .update({
      'ID': orcamento.id,
      'DATA' : orcamento.data,
      'RUA' : orcamento.street,
      'GERADO' : orcamento.generated,
      'BAIRRO' : orcamento.neighborhood,
      'CITY' : orcamento.city,
      'EMAIL' : orcamento.email,
      'ENDERECO' : orcamento.address,
      'FONE' : orcamento.phone,
      'NOMECLIENTE' : orcamento.customerName,
      'NOMEEMPRESA' : orcamento.companyName,
      'STATUS' : orcamento.status,
      'CEP' : orcamento.zip,
      'VALORTOTAL' : orcamento.totalValue}).then((value) async {
    }).then((value) {

    });
  }

  Future<void> EventSave() async{
    final we = MediaQuery.of(context).size.width;
    if(nameButton == "Atualizar")
    {
      orcamento.totalValue = widget.item.totalValue;
      orcamento.id = widget.item.id;
      orcamento.data = widget.item.data;
      orcamento.email = widget.item.email;
      orcamento.address = widget.item.address;
      orcamento.generated = widget.item.generated;
      orcamento.companyName = widget.item.companyName;
      orcamento.customerName = _nameText.text;
      orcamento.phone = _phoneText.text;
      orcamento.status = _statusText.text;
      orcamento.zip = _cepText.text;
      orcamento.street = _ruaText.text;
      orcamento.city = _cityText.text;
      orcamento.neighborhood = _bairroText.text;
      UpdateItensDADOS(orcamento).then((value) {
        setState(() {
          widget.item.totalValue = orcamento.totalValue;
          widget.item.id =  orcamento.id;
          widget.item.data = orcamento.data;
          widget.item.email = orcamento.email;
          widget.item.address = orcamento.address;
          widget.item.generated = orcamento.generated;
          widget.item.companyName = orcamento.companyName;
          widget.item.customerName = _nameText.text;
          widget.item.phone = _phoneText.text;
          widget.item.status = _statusText.text;
          widget.item.zip = _cepText.text;
          widget.item.street = _ruaText.text;
          widget.item.city = _cityText.text;
          widget.item.neighborhood = _bairroText.text;
        });
        AwesomeDialog(
          width: we * 0.99,
          context: context,
          dialogBackgroundColor: Colors.cyan[50],
          animType: AnimType.scale,
          headerAnimationLoop: false,
          dialogType: DialogType.success,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          descTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
          ),
          showCloseIcon: false,
          title: 'Feito!',
          desc: 'Dados do orçamento atualizado com sucesso!',
          btnOkOnPress: () {

          },
          btnOkIcon: Icons.check_circle,
        ).show().then((value) async {

        });
      });
    }
    else if(nameButton == "Continuar")
    {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);
      orcamento.totalValue = 0;
      orcamento.email = widget.item.email;
      orcamento.address = widget.item.address;
      orcamento.generated = widget.item.generated;
      orcamento.companyName = widget.item.companyName;
      orcamento.id = DateTime.now().millisecondsSinceEpoch.toString();
      orcamento.data = formatted;
      orcamento.customerName = _nameText.text;
      orcamento.phone = _phoneText.text;
      orcamento.status = _statusText.text;
      orcamento.zip = _cepText.text;
      orcamento.street = _ruaText.text;
      orcamento.city = _cityText.text;
      orcamento.neighborhood = _bairroText.text;
      saveBudget(orcamento).then((value)  async {
        setState(() {
          widget.item.totalValue =  orcamento.totalValue;
          widget.item.id =  orcamento.id;
          widget.item.data = orcamento.data;
          widget.item.email = orcamento.email;
          widget.item.address = orcamento.address;
          widget.item.generated = orcamento.generated;
          widget.item.companyName = orcamento.companyName;
          widget.item.customerName = _nameText.text;
          widget.item.phone = _phoneText.text;
          widget.item.status = _statusText.text;
          widget.item.zip = _cepText.text;
          widget.item.street = _ruaText.text;
          widget.item.city = _cityText.text;
          widget.item.neighborhood = _bairroText.text;
          Orcamento.ID = widget.item.id;
          Orcamento.DATA = widget.item.data;
          Orcamento.RUA = widget.item.street;
          Orcamento.GERADO = widget.item.generated;
          Orcamento.BAIRRO = widget.item.neighborhood;
          Orcamento.CITY = widget.item.city;
          Orcamento.CEP = widget.item.zip;
          Orcamento.EMAIL = widget.item.email;
          Orcamento.ENDERECO = widget.item.address;
          Orcamento.FONE = widget.item.phone;
          Orcamento.NOMECLIENTE = widget.item.customerName;
          Orcamento.NOMEEMPRESA = widget.item.companyName;
          Orcamento.STATUS = widget.item.status;
          Orcamento.VALORTOTAL = widget.item.totalValue;
          nameButton = 'Atualizar';
          titlePage = 'Editar orçamento';
          titleBox = 'Clique para editar';
          fieldVisible = true;
          _dataText.text = orcamento.data.toString();
          _idText.text = orcamento.id.toString();
        });
        if (await UserInfo.FlutterContacts.requestPermission ()) {
          await AwesomeDialog(
            width: we * 0.99,
            context: context,
            dialogBackgroundColor: Colors.cyan[50],
            animType: AnimType.topSlide,
            headerAnimationLoop: false,
            dialogType: DialogType.success,
            showCloseIcon: false,
            titleTextStyle: const TextStyle(
              color: Colors.black, // Defina a cor do título
              fontSize: 24, // Defina o tamanho da fonte do título
              fontWeight: FontWeight.bold, // Defina o peso da fonte do título
              // Adicione outros atributos do TextStyle conforme necessário
            ),
            descTextStyle: const TextStyle(
              color: Colors.black, // Defina a cor da descrição
              fontSize: 18, // Defina o tamanho da fonte da descrição
              // Adicione outros atributos do TextStyle conforme necessário
            ),
            title: 'Feito!',
            desc: 'Orçamento criado com sucesso!',
            btnOkOnPress: () async {
              await AwesomeDialog(
                context: context,
                width: we * 0.99,
                dialogBackgroundColor: Colors.cyan[50],
                buttonsBorderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
                headerAnimationLoop: false,
                animType: AnimType.bottomSlide,
                titleTextStyle: const TextStyle(
                  color: Colors.black, // Defina a cor do título
                  fontSize: 24, // Defina o tamanho da fonte do título
                  fontWeight: FontWeight.bold, // Defina o peso da fonte do título
                  // Adicione outros atributos do TextStyle conforme necessário
                ),
                descTextStyle: const TextStyle(
                  color: Colors.black, // Defina a cor da descrição
                  fontSize: 18, // Defina o tamanho da fonte da descrição
                  // Adicione outros atributos do TextStyle conforme necessário
                ),
                title: 'Salvar contato',
                desc: 'Gostaria de salvar o telefone em sua lista de contatos?',
                showCloseIcon: false,
                btnCancelText: "Não",
                btnOkText: "Sim",
                btnCancelOnPress: () {
                },
                btnOkOnPress: () async {
                  UserInfo.Contact newContact = UserInfo.Contact()
                    ..name = Name(first: orcamento.customerName.toString())
                    ..phones = [Phone(orcamento.phone.toString()), Phone(orcamento.phone.toString(), label: PhoneLabel.work)];
                  await UserInfo.FlutterContacts.insertContact(newContact);
                },
              ).show().then((value) {
              });
            },
            btnOkIcon: Icons.check_circle,
          ).show();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              height: he * 0.07,
            ),
            GestureDetector(
              onTap: (){
                Navigator.pop(context, true);
              },
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.040),
                child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
              ),
            ),
            SizedBox(
              height: he * 0.03,
            ),
            FadeAnimationWidget(
              delay: 1,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.05),
                child: Text(titlePage!,style: GoogleFonts.heebo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    letterSpacing: 2
                ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: we * 0.05),
              child: Text("Informações do orçamento",style: GoogleFonts.heebo(
                  color: Colors.grey,
                  letterSpacing: 1),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  child: Column(
                      children: <Widget>[
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor,),
                              child: ExpansionTileCard(
                                initiallyExpanded: true,
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                                leading: const CircleAvatar(
                                    backgroundColor: bgColor,
                                    child: Icon(Icons.person_outlined, color: whiteColor,)),
                                title: Text("Contato do cliente",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1
                                ),
                                ),
                                subtitle: Text(titleBox!,style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                    letterSpacing: 1
                                ),
                                ),
                                children:  <Widget>[
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height: he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.fullname ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        focusNode: _name,
                                        readOnly: fieldFone,
                                        controller: _nameText,
                                        onTap: () async {
                                          _name.requestFocus();
                                          AwesomeDialog(
                                            context: context,
                                            width: we * 0.99,
                                            dialogBackgroundColor: Colors.cyan[50],
                                            dialogType: DialogType.infoReverse,
                                            buttonsBorderRadius: const BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                            headerAnimationLoop: false,
                                            animType: AnimType.bottomSlide,
                                            titleTextStyle: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            descTextStyle: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18, // Defina o tamanho da fonte da descrição
                                              // Adicione outros atributos do TextStyle conforme necessário
                                            ),
                                            title: 'Lista de contatos',
                                            desc: 'Gostaria de buscar cliente em sua lista de contatos?',
                                            showCloseIcon: false,
                                            btnCancelText: "Não",
                                            btnOkText: "Sim",
                                            btnCancelOnPress: () {
                                              setState(() {
                                                fieldFone = false;
                                              });

                                            },
                                            btnOkOnPress: () async {
                                              setState(() {
                                                fieldFone = true;
                                              });
                                              int index = 0;
                                              String? nome;
                                              String? tel;
                                              await FlutterContactPicker.pickFullContact().then((value)  {
                                                final FullContact contact = value;
                                                contact.phones.forEach((result) {
                                                  if(index == 0)
                                                  {
                                                    setState(() {
                                                      nome = contact.name?.nickName;
                                                      tel = result.number;
                                                      tel = tel?.replaceAll('+55', '');
                                                      tel = tel?.replaceAll('+', '');
                                                      _nameText.text = nome!;
                                                      _phoneText.text =  maskFormatter.maskText(tel!);
                                                    });
                                                  }
                                                  index++;
                                                });
                                              });
                                            },
                                          ).show();
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.person_outlined,color: selected == Gender.fullname ? enabledtxt : deaible),
                                          hintText: 'Nome do cliente',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.fullname ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.phone ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [maskFormatter],
                                        controller: _phoneText,
                                        focusNode: _phone,
                                        onTap: (){
                                          setState(() {
                                            _phone.requestFocus();
                                            selected = Gender.phone;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.phone_android_outlined, color: selected == Gender.phone ? enabledtxt : deaible),
                                          hintText: 'Telefone',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.phone ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                ],
                              ),),
                          ),
                        ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                            child:Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                              child: ExpansionTileCard(
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                                leading: const CircleAvatar(
                                    backgroundColor: bgColor,
                                    child: Icon(Icons.request_page_outlined, color: whiteColor,)),
                                title:Text("Informações do orçamento",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1
                                ),
                                ),
                                subtitle: Text(titleBox!,style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                    letterSpacing: 1
                                ),
                                ),
                                children:  <Widget>[
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.status ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        readOnly: true,
                                        enableInteractiveSelection: true,
                                        controller: _statusText,
                                        onTap: () async {
                                          List<String> values = ['APROVADO', 'PENDENTE', 'REPROVADO', 'FINALIZADO'];
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SimpleDialog(
                                                backgroundColor: Colors.cyan[50],
                                                title: const Text("Selecione status", style: TextStyle(color: Colors.black),),
                                                children: [
                                                  SizedBox(
                                                    width: MediaQuery.of(context).size.width,
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemBuilder: (ctx, index) {
                                                        return SimpleDialogOption(
                                                          onPressed: () => Navigator.pop(context, values[index]),
                                                          child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(values[index], style: const TextStyle(color: bgColor,
                                                                    fontSize: 15.0)),
                                                              ]
                                                          ),
                                                        );
                                                      },
                                                      itemCount: values.length,
                                                    ),
                                                  )
                                                ],
                                              );
                                            },
                                          ).then((value) => {
                                            setState(() {
                                              _statusText.text = value;
                                            }),

                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.domain_verification_outlined, color: selected == Gender.status ? enabledtxt : deaible),
                                          suffixIcon: Icon(Icons.keyboard_arrow_down_outlined,color: selected == Gender.status ? enabledtxt : deaible,),
                                          hintText: 'Status do orçamentos',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.status ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  Visibility(
                                      visible: fieldVisible,
                                      child: FadeAnimationWidget(
                                        delay: 1,
                                        child: Container(
                                          width: we * 0.8,
                                          height:he * 0.078,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20.0),
                                            color: selected == Gender.data ?  bgColor : bgColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child:  TextField(
                                            controller: _dataText,
                                            onTap: (){
                                              setState(() {
                                                selected = Gender.data;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              enabledBorder: InputBorder.none,
                                              border:InputBorder.none,
                                              enabled: false,
                                              prefixIcon: Icon(Icons.calendar_month_outlined, color: selected == Gender.data ? enabledtxt : deaible,),
                                              hintText: 'Data do orçamento',
                                              hintStyle: const TextStyle(color: Colors.grey),
                                            ),
                                            style:  TextStyle(color:  selected == Gender.data ? enabledtxt : deaible,fontWeight:FontWeight.bold),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  Visibility(
                                      visible: fieldVisible,
                                      child: FadeAnimationWidget(
                                        delay: 1,
                                        child: Container(
                                          width: we * 0.8,
                                          height:he * 0.078,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20.0),
                                            color: selected == Gender.id ?  bgColor : bgColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child:  TextField(
                                            controller: _idText,
                                            onTap: (){
                                              setState(() {
                                                selected = Gender.id;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              enabled: false,
                                              enabledBorder: InputBorder.none,
                                              border:InputBorder.none,
                                              prefixIcon: Icon(Icons.confirmation_number_outlined, color: selected == Gender.id ? enabledtxt : deaible),
                                              hintText: 'Número do orçamento',
                                              hintStyle: const TextStyle(color: Colors.grey),
                                            ),
                                            style:  TextStyle(color:  selected == Gender.id ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                          ),
                                        ),
                                      )
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                              child: ExpansionTileCard(
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                                leading: const CircleAvatar(
                                    backgroundColor: bgColor,
                                    child: Icon(Icons.location_on_outlined, color: whiteColor,)),
                                title: Text("Endereço do cliente",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1
                                ),
                                ),
                                subtitle: Text(titleBox!,style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                    letterSpacing: 1
                                ),
                                ),
                                children:  <Widget>[
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.cep ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) async {
                                          var findAdress = CEP.ViaCepService();
                                          if(value.length == 9)
                                          {
                                            var adress =  await findAdress.getAdress(value);
                                            setState(() {
                                              _ruaText.text = adress.logradouro!.toUpperCase();
                                              _cityText.text = adress.localidade!.toUpperCase();
                                              _bairroText.text = adress.bairro!.toUpperCase();
                                            });
                                          }
                                        },
                                        inputFormatters: [maskCep],
                                        controller: _cepText,
                                        focusNode: _cep,
                                        onTap: (){
                                          setState(() {
                                            _cep.requestFocus();
                                            selected = Gender.cep;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.add_location_outlined, color: selected == Gender.cep ? enabledtxt : deaible),
                                          hintText: 'CEP',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.cep ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.rua ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        focusNode: _rua,
                                        controller: _ruaText,
                                        onTap: (){
                                          setState(() {
                                            _rua.requestFocus();
                                            selected = Gender.rua;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.location_on_outlined, color: selected == Gender.rua ? enabledtxt : deaible),
                                          hintText: 'Rua',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.rua ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.city ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        focusNode: _city,
                                        controller: _cityText,
                                        onTap: (){
                                          setState(() {
                                            _city.requestFocus();
                                            selected = Gender.city;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.location_city_outlined, color: selected == Gender.city ? enabledtxt : deaible),
                                          hintText: 'Cidade',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.city ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.8,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.bairro ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        focusNode: _bairro,
                                        controller: _bairroText,
                                        onTap: (){
                                          setState(() {
                                            selected = Gender.bairro;
                                            _bairro.requestFocus();
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.location_searching, color: selected == Gender.bairro ? enabledtxt : deaible),
                                          hintText: 'Bairro',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.bairro ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: he * 0.02,
                        ),
                        FadeAnimationWidget(
                          delay: 1,
                          child: TextButton(
                            onPressed: () async {
                              await EventSave();
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 70),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)
                                )
                            ),
                            child: Text(nameButton!,style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: he * 0.10,
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ]
      ),
      bottomNavigationBar: _bannerAd != null
          ? SizedBox(width: we, height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!),
      ) : null,
    );
  }
}