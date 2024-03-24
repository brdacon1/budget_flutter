import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/services/convert_coin.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extended_masked_text/extended_masked_text.dart';
import '../../../models/payment_customer.dart';
import '../../../Services/loading_event.dart';
import '../../../common/constants/constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
  descricaoText,
  precoText,
  typeText
}

TextEditingController _typeText = TextEditingController();
TextEditingController _precoText = TextEditingController();
TextEditingController _descricaoText = TextEditingController();

class PaymentCreatorView extends StatefulWidget {
  final PaymentCustomer item;
  const PaymentCreatorView({Key? key, required this.item}) : super(key: key);


  @override
  State<PaymentCreatorView> createState() => _PaymentCreatorView();
}

class _PaymentCreatorView extends State<PaymentCreatorView> {
  Color enabledtxt = Colors.white;
  ConvertCoin moneyConvert = ConvertCoin();
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  PaymentCustomer ITENS = PaymentCustomer();
  final controller = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  final controllerTotal = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  var db = HttpRequest();
  var loadingEvent = LoadingEvent();
  var displayAlert = DisplayAlert();

  @override
  initState() {
    super.initState();
    try{
      setState(()  async {
        if(widget.item.DESCRICAO.toString() != 'null') {
          nameButton = 'ATUALIZAR';
          titlePage = 'Editar pagamento';
          _typeText.text = widget.item.METODO.toString();
          controller.text = moneyConvert.convertFromDouble(widget.item.PRECO!);
          _descricaoText.text = widget.item.DESCRICAO.toString();
          fieldVisible = true;
        }
        else {
          nameButton = 'SALVAR';
          titlePage = 'Criar pagamento';
          _typeText.text = 'Dinheiro';
          controller.text = '';
          _descricaoText.text = '';
          _precoText.text = '1';
          fieldVisible = true;
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
                    child: Text("Dados do pagamento",style: GoogleFonts.heebo(
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
                                    child: Icon(Icons.payments_outlined, color: Colors.white,)),
                                title: Text("Insira dados do pagamento",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1),
                                ),
                                subtitle: Text("Clique para ${titlePage!.toLowerCase()}",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 10,
                                    letterSpacing: 1),
                                ),
                                children:  <Widget>[
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.typeText ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        readOnly: true,
                                        enableInteractiveSelection: true,
                                        controller: _typeText,
                                        onTap: () async {
                                          List<String> values = ['Crédito', 'Débito', 'Dinheiro', 'PIX'];
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SimpleDialog(
                                                backgroundColor: Colors.cyan[50],
                                                title: const Text("Tipo do pagamento", style: TextStyle(color: Colors.black),),
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
                                              _typeText.text = value;
                                            }),

                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.list_alt,color: selected == Gender.typeText ? enabledtxt : deaible),
                                          suffixIcon: Icon(Icons.keyboard_arrow_down_outlined,color: selected == Gender.precoText ? enabledtxt : deaible,),
                                          hintText: 'Definir pagamento',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.typeText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimationWidget(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: selected == Gender.precoText ? bgColor : bgColor
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: controller,
                                        onTap: (){
                                          setState(() {
                                            selected = Gender.precoText;
                                          });
                                        },
                                        decoration: InputDecoration(
                                            enabledBorder: InputBorder.none,
                                            border:InputBorder.none,
                                            prefixIcon: Icon(Icons.price_change_outlined,color: selected == Gender.precoText ? enabledtxt : deaible,),
                                            hintText: 'Preço',
                                            hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style:  TextStyle(color: selected == Gender.precoText ? enabledtxt : deaible,fontWeight:FontWeight.bold),
                                      ),
                                    ),
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
                                          hintText: 'Escreva a descrição do pagamento...',
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
                              double cleanAmount = moneyConvert.convertFromString(controller.text);
                              loadingEvent.alertLoading(context);
                              if(nameButton == 'SALVAR')
                              {
                                ITENS.METODO = _typeText.text;
                                ITENS.DESCRICAO = _descricaoText.text;
                                ITENS.PRECO = cleanAmount;
                                await db.savePaymentCustomer(ITENS).then((value) => {
                                      loadingEvent.closeLoading(context),
                                      displayAlert.notification(context, "Feito!", "Pagamento criado com sucesso!"),
                                });
                              }
                              else if(nameButton == 'ATUALIZAR')
                              {
                                ITENS.METODO = _typeText.text;
                                ITENS.DESCRICAO = _descricaoText.text;
                                ITENS.PRECO = cleanAmount;
                                ITENS.id = widget.item.id;
                                await db.updatePaymentCustomer(ITENS).then((value) => {
                                  loadingEvent.closeLoading(context),
                                  displayAlert.notification(context, "Feito!", "Pagamento atualizado com sucesso!"),
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