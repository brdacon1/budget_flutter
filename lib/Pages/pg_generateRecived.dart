import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oflite/Models/Db.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:oflite/Objetos/DADOS.dart';
import 'package:oflite/Pages/pg_tabRecibos.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Objetos/ObjectRecived.dart';
import '../constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
  descricaoText,
}

TextEditingController _descricaoText = TextEditingController();
TextEditingController _idText = TextEditingController();
TextEditingController _data = TextEditingController();

class PgGenerateRecived extends StatefulWidget {
  final Recived recibos;
  final DADOS item;
  const PgGenerateRecived({Key? key,required this.item, required this.recibos}) : super(key: key);
  @override
  _PgGenerateRecived createState() => _PgGenerateRecived();
}

class _PgGenerateRecived extends State<PgGenerateRecived> {
  Color enabledtxt = Colors.white;
  convert_coin moneyConvert = convert_coin();
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  Recived ITENS = Recived();
  var db = Db();

  @override
  initState() {
    super.initState();
    try{
      setState(()  async {
        if(widget.recibos.DESCRICAO.toString() != 'null') {
          nameButton = 'ATUALIZAR';
          titlePage = 'Editar recibo';
          _descricaoText.text = widget.recibos.DESCRICAO!;
          _idText.text = widget.recibos.ID!;
          _data.text = widget.recibos.DATA!;
          fieldVisible = true;
        }
        else {
          nameButton = 'SALVAR';
          titlePage = 'Criar pagamento';
          _descricaoText.text = '';
          _idText.text = '';
          _data.text = '';
          fieldVisible = false;
        }
      });
    }
    catch (e){
    }
  }

  void notification(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    AwesomeDialog(
      width: width * 0.99,
      context: context,
      dialogBackgroundColor: Colors.cyan[50],
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
      title: firstMessage,
      desc: secondMessage,
      btnOkIcon: Icons.check_circle,
      btnOkOnPress: () {
        Navigator.pop(context, true);
      },
    ).show();
  }

  void notificationError(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    AwesomeDialog(
      width: width * 0.99,
      context: context,
      dialogBackgroundColor: Colors.cyan[50],
      animType: AnimType.leftSlide,
      headerAnimationLoop: false,
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
      dialogType: DialogType.error,
      showCloseIcon: false,
      title: firstMessage,
      desc: secondMessage,
      btnOkOnPress: () async {},
      btnOkIcon: Icons.check_circle,).show();
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: SizedBox(
          width: we,
          height: he,
          child: Column(
              children: <Widget>[
                SizedBox(
                  height: he * 0.07,
                ),
                GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: we * 0.04),
                    child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
                  ),
                ),
                SizedBox(
                  height: he * 0.02,
                ),
                FadeAnimation(
                  delay: 1,
                  child: Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: we * 0.048),
                    child: Text(titlePage!,style: GoogleFonts.heebo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: 1
                    ),
                    ),
                  ),
                ),
                FadeAnimation(
                  delay: 1,
                  child: Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: we * 0.05),
                    child: Text("Dados do recibo",style: GoogleFonts.heebo(
                        color: Colors.grey,
                        letterSpacing: 1),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                      children: <Widget>[
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 0),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: bgColor),
                              child: ExpansionTileCard(
                                initiallyExpanded: true,
                                expandedTextColor: bgColor,
                                baseColor: Colors.cyan[50],
                                expandedColor: Colors.cyan[50],
                                leading: const CircleAvatar(
                                    backgroundColor: bgColor,
                                    child: Icon(Icons.shopping_cart_outlined, color: Colors.white,)),
                                title: Text("Clique para ${titlePage!.toLowerCase()}",style: GoogleFonts.heebo(
                                    color: bgColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
                                    letterSpacing: 1),
                                ),
                                subtitle: Text("Dados do pagamento",style: GoogleFonts.heebo(
                                    color: bgColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1),
                                ),
                                children:  <Widget>[
                                  Visibility(
                                      visible: fieldVisible,
                                      child: FadeAnimation(
                                        delay: 1,
                                        child: Container(
                                          width: we * 0.8,
                                          height:he * 0.071,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20.0),
                                            color: selected == Gender.descricaoText ?  bgColor : bgColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child:  TextField(
                                            controller: _idText,
                                            onTap: (){
                                              setState(() {
                                                selected = Gender.descricaoText;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              enabled: false,
                                              enabledBorder: InputBorder.none,
                                              border:InputBorder.none,
                                              prefixIcon: Icon(Icons.confirmation_number_outlined, color: selected == Gender.descricaoText ? enabledtxt : deaible),
                                              hintText: 'Número do recibo',
                                              hintStyle: TextStyle(
                                                color:  selected == Gender.descricaoText ? enabledtxt : deaible,
                                              ),
                                            ),
                                            style:  TextStyle(color:  selected == Gender.descricaoText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                          ),
                                        ),
                                      )
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
                                            color: selected == Gender.descricaoText ?  bgColor : bgColor,
                                          ),
                                          padding: const EdgeInsets.all(8.0),
                                          child:  TextField(
                                            controller: _data,
                                            onTap: (){
                                              setState(() {
                                                selected = Gender.descricaoText;
                                              });
                                            },
                                            decoration: InputDecoration(
                                              enabled: false,
                                              enabledBorder: InputBorder.none,
                                              border:InputBorder.none,
                                              prefixIcon: Icon(Icons.calendar_month_outlined, color: selected == Gender.descricaoText ? enabledtxt : deaible),
                                              hintText: 'Data do recibo',
                                              hintStyle: TextStyle(
                                                color:  selected == Gender.descricaoText ? enabledtxt : deaible,
                                              ),
                                            ),
                                            style:  TextStyle(color:  selected == Gender.descricaoText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                          ),
                                        ),
                                      )
                                  ),
                                  Padding(padding: const EdgeInsets.only(top: 10, bottom: 20),
                                    child: Container(
                                      width: we * 0.80,
                                      height: he * 0.30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.descricaoText ? bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: _descricaoText,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 50,
                                        onTap: () {
                                          setState(() {
                                            selected = Gender.descricaoText;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border: InputBorder.none,
                                          hintText: 'Escreva a descrição do recibo...',
                                          hintStyle: TextStyle(color: Colors.grey),
                                        ),
                                        style: TextStyle(
                                          color: selected == Gender.descricaoText ? enabledtxt : deaible,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 20),
                          child: TextButton(
                            onPressed: () async {
                              if(nameButton == 'SALVAR')
                              {
                                final DateTime now = DateTime.now();
                                final DateFormat formatter = DateFormat('dd/MM/yyyy');
                                final String formatted = formatter.format(now);
                                ITENS.DESCRICAO = _descricaoText.text;
                                ITENS.ID = DateTime.now().millisecondsSinceEpoch.toString();
                                ITENS.DATA = formatted;
                                ITENS.VALORTOTAL = 0;
                                await db.savedRecived(ITENS).then((value) async => {
                                await Navigator.push(
                                      context,
                                         MaterialPageRoute(builder: (context) => PageTabRecibos(item: widget.item, recibos: ITENS,)),
                                      ).then((value) async => {
                                         setState(() {}),}),
                                });
                              }
                              else if(nameButton == 'ATUALIZAR' && fieldVisible == false)
                              {
                                ITENS.DESCRICAO = _descricaoText.text;
                                ITENS.ID = widget.recibos.ID;
                                ITENS.DATA = widget.recibos.DATA;
                                ITENS.VALORTOTAL = widget.recibos.VALORTOTAL;
                                await db.savedRecived(ITENS).then((value) => {
                                  notification(context, "Feito!", "Pagamento atualizado com sucesso!"),
                                });
                              }
                            },
                            style:  TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 80),
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
                          height: he * 0.3,
                        ),
                      ]
                  ),
                ),
              ]
          ),
        ),
      ),
    );
  }
}