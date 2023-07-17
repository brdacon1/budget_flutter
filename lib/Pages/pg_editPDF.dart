import 'dart:typed_data';

import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Objetos/Owner.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import '../Models/Db.dart';
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
import 'package:oflite/Objetos/globalUIDUser.dart' as globalUIDUser;
import '../constants.dart';
import 'package:http/http.dart' as http;

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
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

TextEditingController _nameText = TextEditingController();
TextEditingController _phoneText = TextEditingController();
TextEditingController _emailText = TextEditingController();
TextEditingController _cpfText = TextEditingController();
TextEditingController _cepText = TextEditingController();
TextEditingController _ruaText = TextEditingController();
TextEditingController _cityText = TextEditingController();
TextEditingController _bairroText = TextEditingController();

class PgEditPDF extends StatefulWidget {
  const PgEditPDF({Key? key}) : super(key: key);
  @override
  _PgEditPDF createState() => _PgEditPDF();
}

class _PgEditPDF extends State<PgEditPDF> {
  Owner owner = Owner();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  final GlobalKey<ExpansionTileCardState> cardA = GlobalKey();
  late Future<Uint8List?> fileContentFuture;

  var maskFormatter =  MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskFormatterCNPJ =  MaskTextInputFormatter(
      mask: '##.###.###/0001-##',
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

  Future<Uint8List?> initialData() async {
    var db = Db();
    var ownerInitial = await db.getInformationEnterprise();
    owner = ownerInitial;
    var auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: globalUIDUser.EMAIL!.trim(),
      password: globalUIDUser.Senha!.trim(),
    );
    var token = await auth.user?.getIdToken();
    var endpointUrl =
        'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=${owner.fotoId}';
    var response = await http.get(
      Uri.parse(endpointUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json;odata=verbose',
      },
    );

    _nameText.text = owner.empresa!;
    _phoneText.text = owner.fone!;
    _emailText.text = owner.email!;
    _cpfText.text = owner.cnpj!;
    _cepText.text = owner.cep!;
    _ruaText.text = owner.rua!;
    _cityText.text = owner.city!;
    _bairroText.text = owner.bairro!;
    print(owner.fotoId!);
    setState(() {});

    return response.bodyBytes;
  }

  @override
  initState() {
    super.initState();
    fileContentFuture = initialData();
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
                child: Text('Editar PDF',style: GoogleFonts.heebo(
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
              child: Text("Informações do PDF",style: GoogleFonts.heebo(
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
                          height: he * 0.02,
                      ),
                      FutureBuilder<Uint8List?>(
                                future: fileContentFuture,
                                builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                 } else if (snapshot.hasError) {
                                    return const Text('Erro ao carregar a imagem');
                                 } else {
                                 return GestureDetector(
                                     onTap: () {
                                      // Seu código de ação ao tocar no avatar (se necessário).
                                 },
                                     child: CircleAvatar(
                                     radius: 100,
                                     backgroundImage: MemoryImage(snapshot.data!),
                          ),
                        );
                      }
                    },
                      ),
                      SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                            child: ExpansionTileCard(
                              baseColor: Colors.cyan[50],
                              expandedColor: Colors.cyan[50],
                              leading: const CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(Icons.account_balance, color: Colors.white,)),
                              title: Text("Clique para editar",style: GoogleFonts.heebo(
                                  color: bgColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                  letterSpacing: 1
                              ),
                              ),
                              subtitle: Text("Informações da empresa",style: GoogleFonts.heebo(
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
                                      readOnly: false,
                                      controller: _nameText,
                                      onTap: () async {

                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.account_balance,color: selected == Gender.fullname ? enabledtxt : deaible),
                                        hintText: 'Nome da empresa',
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
                                FadeAnimation(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.email ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _emailText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.email;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.email_outlined, color: selected == Gender.email ? enabledtxt : deaible),
                                        hintText: 'E-mail',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.email ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.email ? enabledtxt : deaible, fontWeight:FontWeight.bold),
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
                                      inputFormatters: [maskFormatterCNPJ],
                                      controller: _cpfText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.cpf;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.contact_page_outlined, color: selected == Gender.cpf ? enabledtxt : deaible),
                                        hintText: 'CNPJ',
                                        hintStyle: TextStyle(
                                          color:  selected == Gender.cpf ? enabledtxt : deaible,
                                        ),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.cpf ? enabledtxt : deaible, fontWeight:FontWeight.bold),
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
                                  child: Icon(Icons.location_on_outlined, color: Colors.white,)),
                              title: Text("Clique para editar",style: GoogleFonts.heebo(
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

                            },
                            style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 70),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)
                                )
                            ),
                            child: Text("Atualizar",style: GoogleFonts.heebo(
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
