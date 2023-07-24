import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:flutter_contacts/properties/phone.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import '../Objetos/DADOS.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/Models/ViaCEPServico.dart' as CEP;
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as UserInfo;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:intl/intl.dart';

import '../constants.dart';

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

class GeradorOrcamento extends StatefulWidget {
  final DADOS item;
  const GeradorOrcamento({Key? key, required this.item}) : super(key: key);
  @override
  _GeradorOrcamento createState() => _GeradorOrcamento();
}

class _GeradorOrcamento extends State<GeradorOrcamento> {
  DADOS orcamento = DADOS();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  String? titleBox;
  bool fieldVisible = false;
  bool fieldFone = true;

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
      setState(()  async {
        Orcamento.ID = widget.item.ID;
        Orcamento.DATA = widget.item.DATA;
        Orcamento.RUA = widget.item.RUA;
        Orcamento.GERADO = widget.item.GERADO;
        Orcamento.BAIRRO = widget.item.BAIRRO;
        Orcamento.CITY = widget.item.CITY;
        Orcamento.CEP = widget.item.CEP;
        Orcamento.EMAIL = widget.item.EMAIL;
        Orcamento.ENDERECO = widget.item.ENDERECO;
        Orcamento.FONE = widget.item.FONE;
        Orcamento.NOMECLIENTE = widget.item.NOMECLIENTE;
        Orcamento.NOMEEMPRESA = widget.item.NOMEEMPRESA;
        Orcamento.STATUS = widget.item.STATUS;
        Orcamento.VALORTOTAL = widget.item.VALORTOTAL;

        if(widget.item.ID.toString() != '')
        {
          nameButton = 'ATUALIZAR';
          titlePage = 'Editar orçamento';
          titleBox = 'Clique para editar';
          fieldVisible = true;
        }
        else
        {
          nameButton = 'SALVAR';
          titlePage = 'Criar orçamento';
          titleBox = 'Clique para inserir';
          fieldVisible = false;
        }
        _nameText.text = widget.item.NOMECLIENTE.toString();
        _dataText.text = widget.item.DATA.toString();
        _idText.text = widget.item.ID.toString();

        if(widget.item.RUA.toString() != 'null')
        {
          _ruaText.text = widget.item.RUA.toString();
        }
        else
        {
          _ruaText.text = '';
        }
        if(widget.item.CITY.toString() != 'null')
        {
          _cityText.text = widget.item.CITY.toString();
        }
        else
        {
          _cityText.text = '';
        }
        if(widget.item.FONE.toString() != 'null')
        {
          _phoneText.text = maskFormatter.maskText(widget.item.FONE.toString());

        }
        else
        {
          _phoneText.text = '';
        }
        if(widget.item.BAIRRO.toString() != 'null')
        {
          _bairroText.text = widget.item.BAIRRO.toString();
        }
        else
        {
          _bairroText.text = '';
        }
        if(widget.item.STATUS.toString() != 'null')
        {
          _statusText.text = widget.item.STATUS.toString();
        }
        else
        {
          _statusText.text = '';
        }
        if(widget.item.CEP.toString() != 'null')
        {
          _cepText.text = maskCep.maskText(widget.item.CEP.toString());
        }
        else
        {
          _cepText.text = '';
        }
      });
    }
    catch (e) {}
  }

  Future <void> saveBudget(DADOS orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .doc(orcamento.ID)
        .set({
        'ID': orcamento.ID,
        'DATA' : orcamento.DATA,
        'RUA' : orcamento.RUA,
        'GERADO' : orcamento.GERADO,
        'BAIRRO' : orcamento.BAIRRO,
        'CITY' : orcamento.CITY,
        'EMAIL' : orcamento.EMAIL,
        'ENDERECO' : orcamento.ENDERECO,
        'FONE' : orcamento.FONE,
        'NOMECLIENTE' : orcamento.NOMECLIENTE,
        'NOMEEMPRESA' : orcamento.NOMEEMPRESA,
        'STATUS' : orcamento.STATUS,
        'CEP' : orcamento.CEP,
        'VALORTOTAL': orcamento.VALORTOTAL}).then((value) async {
         }).then((value) {
            Orcamento.IDORCAMENTO = orcamento.ID;
            Orcamento.VALORTOTAL = orcamento.VALORTOTAL ?? 0;
        });
  }

  Future <void> UpdateItensDADOS(DADOS orcamento) async {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
          .doc(widget.item.ID)
          .update({
           'ID': orcamento.ID,
           'DATA' : orcamento.DATA,
           'RUA' : orcamento.RUA,
           'GERADO' : orcamento.GERADO,
           'BAIRRO' : orcamento.BAIRRO,
           'CITY' : orcamento.CITY,
           'EMAIL' : orcamento.EMAIL,
           'ENDERECO' : orcamento.ENDERECO,
           'FONE' : orcamento.FONE,
           'NOMECLIENTE' : orcamento.NOMECLIENTE,
           'NOMEEMPRESA' : orcamento.NOMEEMPRESA,
           'STATUS' : orcamento.STATUS,
           'CEP' : orcamento.CEP,
           'VALORTOTAL' : orcamento.VALORTOTAL}).then((value) async {
          }).then((value) {

          });
  }

  Future<void> EventSave() async{
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    if(nameButton == "ATUALIZAR")
    {
      orcamento.VALORTOTAL = widget.item.VALORTOTAL;
      orcamento.ID = widget.item.ID;
      orcamento.DATA = widget.item.DATA;
      orcamento.EMAIL = widget.item.EMAIL;
      orcamento.ENDERECO = widget.item.ENDERECO;
      orcamento.GERADO = widget.item.GERADO;
      orcamento.NOMEEMPRESA = widget.item.NOMEEMPRESA;
      orcamento.NOMECLIENTE = _nameText.text;
      orcamento.FONE = _phoneText.text;
      orcamento.STATUS = _statusText.text;
      orcamento.CEP = _cepText.text;
      orcamento.RUA = _ruaText.text;
      orcamento.CITY = _cityText.text;
      orcamento.BAIRRO = _bairroText.text;
      UpdateItensDADOS(orcamento).then((value) {
        setState(() {
          widget.item.VALORTOTAL = orcamento.VALORTOTAL;
          widget.item.ID =  orcamento.ID;
          widget.item.DATA = orcamento.DATA;
          widget.item.EMAIL = orcamento.EMAIL;
          widget.item.ENDERECO = orcamento.ENDERECO;
          widget.item.GERADO = orcamento.GERADO;
          widget.item.NOMEEMPRESA = orcamento.NOMEEMPRESA;
          widget.item.NOMECLIENTE = _nameText.text;
          widget.item.FONE = _phoneText.text;
          widget.item.STATUS = _statusText.text;
          widget.item.CEP = _cepText.text;
          widget.item.RUA = _ruaText.text;
          widget.item.CITY = _cityText.text;
          widget.item.BAIRRO = _bairroText.text;
        });
        AwesomeDialog(
          width: we * 0.99,
          context: context,
          dialogBackgroundColor: Colors.cyan[50],
          animType: AnimType.scale,
          headerAnimationLoop: false,
          dialogType: DialogType.success,
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
    else if(nameButton == "SALVAR")
    {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);
      orcamento.VALORTOTAL = 0;
      orcamento.EMAIL = widget.item.EMAIL;
      orcamento.ENDERECO = widget.item.ENDERECO;
      orcamento.GERADO = widget.item.GERADO;
      orcamento.NOMEEMPRESA = widget.item.NOMEEMPRESA;
      orcamento.ID = DateTime.now().millisecondsSinceEpoch.toString();
      orcamento.DATA = formatted;
      orcamento.NOMECLIENTE = _nameText.text;
      orcamento.FONE = _phoneText.text;
      orcamento.STATUS = _statusText.text ?? 'PENDENTE';
      orcamento.CEP = _cepText.text;
      orcamento.RUA = _ruaText.text;
      orcamento.CITY = _cityText.text;
      orcamento.BAIRRO = _bairroText.text;
      saveBudget(orcamento).then((value)  async {
        setState(() {
          widget.item.VALORTOTAL =  orcamento.VALORTOTAL;
          widget.item.ID =  orcamento.ID;
          widget.item.DATA = orcamento.DATA;
          widget.item.EMAIL = orcamento.EMAIL;
          widget.item.ENDERECO = orcamento.ENDERECO;
          widget.item.GERADO = orcamento.GERADO;
          widget.item.NOMEEMPRESA = orcamento.NOMEEMPRESA;
          widget.item.NOMECLIENTE = _nameText.text;
          widget.item.FONE = _phoneText.text;
          widget.item.STATUS = _statusText.text ?? 'PENDENTE';
          widget.item.CEP = _cepText.text;
          widget.item.RUA = _ruaText.text;
          widget.item.CITY = _cityText.text;
          widget.item.BAIRRO = _bairroText.text;
          nameButton = 'ATUALIZAR';
          titlePage = 'Editar orçamento';
          titleBox = 'Clique para editar';
          fieldVisible = true;
          _dataText.text = orcamento.DATA.toString();
          _idText.text = orcamento.ID.toString();
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
                    ..name = Name(first: orcamento.NOMECLIENTE.toString())
                    ..phones = [Phone(orcamento.FONE.toString()), Phone(orcamento.FONE.toString(), label: PhoneLabel.work)];
                  await UserInfo.FlutterContacts.insertContact(newContact).then((value) async {

                  });
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
            FadeAnimation(
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
                            child: ExpansionTileCard(
                              baseColor: Colors.cyan[50],
                              expandedColor: Colors.cyan[50],
                              leading: const CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(Icons.person_outlined, color: Colors.white,)),
                              title: Text(titleBox!,style: GoogleFonts.heebo(
                                  color: bgColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                  letterSpacing: 1
                              ),
                              ),
                              subtitle: Text("Informações do cliente",style: GoogleFonts.heebo(
                                  color: bgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1
                              ),
                              ),
                              children:  <Widget>[
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height: he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.fullname ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                        readOnly: fieldFone,
                                        controller: _nameText,
                                        onTap: () async {
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
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.fullname ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.fullname ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.phone ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [maskFormatter],
                                      controller: _phoneText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.phone;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.phone_android_outlined, color: selected == Gender.phone ? enabledtxt : deaible),
                                        hintText: 'Telefone',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.phone ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.phone ? enabledtxt : deaible, fontWeight:FontWeight.bold),
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
                   SizedBox(
                      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                      child: ExpansionTileCard(
                      baseColor: Colors.cyan[50],
                      expandedColor: Colors.cyan[50],
                      leading: const CircleAvatar(
                          backgroundColor: bgColor,
                          child: Icon(Icons.request_page_outlined, color: Colors.white,)),
                          title: Text(titleBox!,style: GoogleFonts.heebo(
                          color: bgColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                          letterSpacing: 1
                        ),
                      ),
                      subtitle: Text("Informações do orçamento",style: GoogleFonts.heebo(
                          color: bgColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1
                      ),
                      ),
                      children:  <Widget>[
                        SizedBox(
                          height: he * 0.02,
                        ),
                        FadeAnimation(
                          delay: 1,
                          child: Container(
                            width: we * 0.8,
                            height:he * 0.071,
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
                                    title: const Text("Selecione status"),
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
                                hintStyle: TextStyle(
                                  color:  selected == Gender.status ? enabledtxt : deaible,
                                ),
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
                            child: FadeAnimation(
                              delay: 1,
                              child: Container(
                                width: we * 0.8,
                                height:he * 0.071,
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
                                    hintStyle: TextStyle(
                                      color:  selected == Gender.data ? enabledtxt : deaible,
                                    ),
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
                            child: FadeAnimation(
                              delay: 1,
                              child: Container(
                                width: we * 0.8,
                                height:he * 0.071,
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
                                    hintStyle: TextStyle(
                                      color:  selected == Gender.id ? enabledtxt : deaible,
                                    ),
                                  ),
                                  style:  TextStyle(color:  selected == Gender.id ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                ),
                              ),
                            )),
                          SizedBox(
                          height: he * 0.02,
                            ),
                           ],
                          ),
                         ),
                        ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
                            child: ExpansionTileCard(
                              baseColor: Colors.cyan[50],
                              expandedColor: Colors.cyan[50],
                              leading: const CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(Icons.location_on_outlined, color: Colors.white,)),
                              title: Text(titleBox!,style: GoogleFonts.heebo(
                                  color: bgColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                  letterSpacing: 1
                              ),
                              ),
                              subtitle: Text("Informações de endereço",style: GoogleFonts.heebo(
                                  color: bgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1
                              ),
                              ),
                              children:  <Widget>[
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.cep ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                         keyboardType: TextInputType.number,
                                         onChanged: (value) async {
                                         var findAdress = CEP.ViaCEPServico();
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
                                        onTap: (){
                                          setState(() {
                                            selected = Gender.cep;
                                          });
                                        },
                                       decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.add_location_outlined, color: selected == Gender.cep ? enabledtxt : deaible),
                                        hintText: 'CEP',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.cep ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.cep ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.rua ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _ruaText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.rua;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_on_outlined, color: selected == Gender.rua ? enabledtxt : deaible),
                                        hintText: 'Rua',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.rua ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.rua ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.city ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _cityText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.city;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_city_outlined, color: selected == Gender.city ? enabledtxt : deaible),
                                        hintText: 'Cidade',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.city ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.city ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.bairro ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _bairroText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.bairro;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_searching, color: selected == Gender.bairro ? enabledtxt : deaible),
                                        hintText: 'Bairro',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.bairro ? enabledtxt : deaible,
                                        ),
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
                        SizedBox(
                          height: he * 0.02,
                        ),
                        FadeAnimation(
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
    );
  }
}
