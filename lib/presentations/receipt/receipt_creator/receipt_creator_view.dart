import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/services//convert_coin.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/receipt.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';
import '../../../common/constants/constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
  descricaoText,
}

TextEditingController _descricaoText = TextEditingController();
TextEditingController _idText = TextEditingController();
TextEditingController _data = TextEditingController();

class ReceiptCreatorView extends StatefulWidget {
  final Receipt receipt;
  final CustomerInfo item;
  const ReceiptCreatorView({Key? key,required this.item, required this.receipt}) : super(key: key);

  @override
  State<ReceiptCreatorView> createState() => _ReceiptCreatorView();
}

class _ReceiptCreatorView extends State<ReceiptCreatorView> {
  Color enabledtxt = Colors.white;
  ConvertCoin moneyConvert = ConvertCoin();
  var displayAlert = DisplayAlert();
  var loadingEvent = LoadingEvent();
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  Receipt ITENS = Receipt();
  var db = HttpRequest();

  @override
  initState() {
    super.initState();
    try{
      setState(()  async {
        if(widget.receipt.DESCRICAO.toString() != 'null') {
          nameButton = 'ATUALIZAR';
          titlePage = 'Editar recibo';
          _descricaoText.text = widget.receipt.DESCRICAO!;
          _idText.text = widget.receipt.ID!;
          _data.text = widget.receipt.DATA!;
          fieldVisible = true;
        }
        else {
          nameButton = 'SALVAR';
          titlePage = 'Criar recibo';
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
                FadeAnimationWidget(
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
                FadeAnimationWidget(
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
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                              child: ExpansionTileCard(
                                initiallyExpanded: true,
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                                leading: const CircleAvatar(
                                    backgroundColor: bgColor,
                                    child: Icon(Icons.receipt_long_rounded, color: whiteColor,)),
                                title: Text("Insira dados do recibo",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1),
                                ),
                                subtitle: Text("Clique para ${titlePage!.toLowerCase()}",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                    letterSpacing: 1),
                                ),
                                children:  <Widget>[
                                  Visibility(
                                      visible: fieldVisible,
                                      child: FadeAnimationWidget(
                                        delay: 1,
                                        child: Container(
                                          width: we * 0.8,
                                          height:he * 0.078,
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
                                              hintStyle: const TextStyle(color: Colors.grey),
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
                                      child: FadeAnimationWidget(
                                        delay: 1,
                                        child: Container(
                                          width: we * 0.8,
                                          height:he * 0.078,
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
                                              hintStyle: const TextStyle(color: Colors.grey),
                                            ),
                                            style:  TextStyle(color:  selected == Gender.descricaoText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                          ),
                                        ),
                                      )
                                  ),
                                  Padding(padding: const EdgeInsets.only(top: 10, bottom: 20),
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.075,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.descricaoText ? bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: _descricaoText,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 1,
                                        onTap: () {
                                          setState(() {
                                            selected = Gender.descricaoText;
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border: InputBorder.none,
                                          hintText: 'Digite nome do recibo...',
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
                              loadingEvent.alertLoading(context);
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
                                  loadingEvent.closeLoading(context),
                                  displayAlert.notificationNotCloseScreen(context, "Feito!", "Recibo criado com sucesso!"),
                                  widget.receipt.DATA = ITENS.DATA,
                                  widget.receipt.ID = ITENS.ID,
                                  widget.receipt.VALORTOTAL = ITENS.VALORTOTAL,
                                  widget.receipt.DESCRICAO = ITENS.DESCRICAO,
                                  _data.text = widget.receipt.DATA!,
                                  _descricaoText.text = widget.receipt.DESCRICAO!,
                                  _idText.text = widget.receipt.ID!,
                                  fieldVisible = true,
                                  setState(() {}),
                                });
                              }
                              else if(nameButton == 'ATUALIZAR' && fieldVisible == true)
                              {
                                ITENS.DESCRICAO = _descricaoText.text;
                                ITENS.ID = widget.receipt.ID;
                                ITENS.DATA = widget.receipt.DATA;
                                ITENS.VALORTOTAL = widget.receipt.VALORTOTAL;
                                await db.savedRecived(ITENS).then((value) => {
                                    loadingEvent.closeLoading(context),
                                    displayAlert.notificationNotCloseScreen(context, "Feito!", "Recibo atualizado com sucesso!"),
                                    setState(() {}),
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