import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/convert_coin.dart';
import 'package:oflite/anmition/fadeanimation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/Db.dart';
import '../Objetos/ObjectListItens.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import 'package:extended_masked_text/extended_masked_text.dart';

import '../constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
  categoriaText,
  unidadeText,
  qtdText,
  descricaoText,
}

TextEditingController _categoriaText = TextEditingController();
TextEditingController _unidadeText = TextEditingController();
TextEditingController _qtdText = TextEditingController();
TextEditingController _descricaoText = TextEditingController();

class PgCreateProduct extends StatefulWidget {
  final ObjectListItens item;
  const PgCreateProduct({Key? key, required this.item}) : super(key: key);
  @override
  _PgCreateProduct createState() => _PgCreateProduct();
}

class _PgCreateProduct extends State<PgCreateProduct> {
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  String? titlePage;
  bool fieldVisible = false;
  var db = Db();
  ObjectListItens ITENS = ObjectListItens();
  final controller = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  final controllerTotal = MoneyMaskedTextController(leftSymbol: 'R\$ ');
  convert_coin moneyConvert = convert_coin();

  @override
  initState() {
    setState(() {
      if(widget.item.DESCRICAO.toString() != 'null')
      {
        nameButton = 'ATUALIZAR';
        titlePage = 'Editar item';
        _categoriaText.text = widget.item.CATEGORIA.toString();
        _unidadeText.text = widget.item.MEDIDA.toString();
        _qtdText.text = widget.item.QTD.toString();
        controller.text = moneyConvert.convertFromDouble(widget.item.PRECO!);
        _descricaoText.text = widget.item.DESCRICAO.toString();
        print(widget.item.IDPRODUCT.toString());
        if(widget.item.IDPRODUCT.toString() == 'null')
        {
          fieldVisible = false;
        }
        else
        {
          fieldVisible = true;
        }
      }
      else
      {
        if(Orcamento.fromListItem == true) {
          fieldVisible = true;
        }
        else{
          fieldVisible = false;
        }
        nameButton = 'SALVAR';
        titlePage = 'Criar item';
        _categoriaText.text = 'Serviços';
        _unidadeText.text = '';
        _qtdText.text = '';
        controller.text = '';
        _descricaoText.text = '';
      }
    });
    super.initState();
  }

  Future <void> UpadateItensInPriceList(ObjectListItens itens) async {
    try{
            await FirebaseFirestore.instance
                  .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/PRICELIST")
                  .doc(widget.item.id)
                  .update({'CATEGORIA': itens.CATEGORIA,
                  'DESCRICAO' : itens.DESCRICAO,
                  'PRECO' : itens.PRECO,
                  'QTD' : itens.QTD,
                  'MEDIDA' : itens.MEDIDA,
                  'TOTAL' : itens.TOTAL,
                  'COLOR': 'false',
                  'IDPRODUCT': itens.IDPRODUCT,}).then((value) async {});
    } catch (e) {
      notificationError(context, "Erro!", "Não foi possível atualizar o item em sua lista de preço");
    }
  }

  Future <void> UpdateItensOrcamentoList(ObjectListItens itens) async {
    try{
          await FirebaseFirestore.instance
                .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/ITENS")
                .doc(widget.item.IDPRODUCT)
                .update({'CATEGORIA': itens.CATEGORIA ?? 'Serviços',
                'DESCRICAO' : itens.DESCRICAO,
                'PRECO' : itens.PRECO,
                'QTD' : itens.QTD,
                'MEDIDA' : itens.MEDIDA,
                'TOTAL' : itens.TOTAL,
                'COLOR': widget.item.checkBox,
                'IDPRODUCT': widget.item.IDPRODUCT,}).then((value) async {});
    }
    catch (e) {
      notificationError(context, "Erro!", "Não foi possível atualizar o item na lista de orçamentos.");
    }
  }

  Future <String> SaveItensInPriceList(ObjectListItens itens) async {
    String id = '';
    try{
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/PRICELIST")
          .add({'CATEGORIA': itens.CATEGORIA,
        'DESCRICAO' : itens.DESCRICAO,
        'PRECO' : itens.PRECO,
        'QTD' : itens.QTD,
        'MEDIDA' : itens.MEDIDA,
        'TOTAL' : itens.TOTAL,
        'COLOR': 'false',
        'IDPRODUCT': itens.IDPRODUCT,
      }).then((value) async {
         id = value.id;
      });
    }catch (e){
      notificationError(context, "Erro!", "Não foi possível adicionar um novo item em sua lista de preço");
    }
    return id;
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
                    child: Text("Cadastro de produto ou serviço",style: GoogleFonts.heebo(
                        color: Colors.grey,
                        letterSpacing: 1),
                    ),
                  ),
                ),
                SizedBox(
                    height: he * 0.02
                ),
                Expanded(
                  child: ListView(
                        children: <Widget>[
                          SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
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
                                subtitle: Text("Dados do produto ou serviço",style: GoogleFonts.heebo(
                                    color: bgColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1),
                                ),
                                children:  <Widget>[
                                  FadeAnimation(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.categoriaText ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        readOnly: true,
                                        enableInteractiveSelection: true,
                                        controller: _categoriaText,
                                        onTap: () async {
                                          List<String> values = ['Produtos', 'Serviços'];
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SimpleDialog(
                                                backgroundColor: Colors.cyan[50],
                                                title: const Text("Selecione categoria", style: TextStyle(color: Colors.black),),
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
                                              _categoriaText.text = value;
                                            }),

                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.list_alt,color: selected == Gender.categoriaText ? enabledtxt : deaible),
                                          suffixIcon: Icon(Icons.keyboard_arrow_down_outlined,color: selected == Gender.categoriaText ? enabledtxt : deaible,),
                                          hintText: 'Definir categoria',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.categoriaText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimation(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20.0),
                                        color: selected == Gender.unidadeText ?  bgColor : bgColor,
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child:  TextField(
                                        controller: _unidadeText,
                                        onTap: (){
                                          setState(() {
                                            selected = Gender.unidadeText;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          enabledBorder: InputBorder.none,
                                          border:InputBorder.none,
                                          prefixIcon: Icon(Icons.analytics_outlined,color: selected == Gender.unidadeText ? enabledtxt : deaible,),
                                          hintText: 'Unidade de medida',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        style:  TextStyle(color:  selected == Gender.unidadeText ? enabledtxt : deaible,fontWeight:FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: he * 0.02,
                                  ),
                                  FadeAnimation(
                                    delay: 1,
                                    child: Container(
                                      width: we * 0.80,
                                      height:he * 0.078,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: selected == Gender.unidadeText ? bgColor : bgColor
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: controller,
                                        onTap: (){
                                          setState(() {
                                            selected = Gender.unidadeText;
                                          });
                                        },
                                        decoration: InputDecoration(
                                            enabledBorder: InputBorder.none,
                                            border:InputBorder.none,
                                            prefixIcon: Icon(Icons.price_change_outlined,color: selected == Gender.unidadeText ? enabledtxt : deaible,),
                                            hintText: 'Preço',
                                            hintStyle: const TextStyle(color: Colors.grey),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style:  TextStyle(color: selected == Gender.unidadeText ? enabledtxt : deaible,fontWeight:FontWeight.bold),
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
                                        width: we * 0.80,
                                        height:he * 0.078,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: selected == Gender.qtdText ?  bgColor : bgColor,
                                        ),
                                        padding: const EdgeInsets.all(8.0),
                                        child:  TextField(
                                          controller: _qtdText,
                                          keyboardType: TextInputType.number,
                                          onTap: (){
                                            setState(() {
                                              selected = Gender.qtdText;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            enabledBorder: InputBorder.none,
                                            border:InputBorder.none,
                                            prefixIcon: Icon(Icons.calculate_outlined,color: selected == Gender.qtdText ? enabledtxt : deaible),
                                            hintText: 'Quantidade',
                                            hintStyle: const TextStyle(color: Colors.grey),
                                          ),
                                          style:  TextStyle(color:  selected == Gender.qtdText ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                        ),
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
                                           hintText: 'Escreva a descrição do produto ou serviço...',
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
                          Padding(padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                  child: TextButton(
                                    onPressed: () async {
                                      double cleanAmount = moneyConvert.convertFromString(controller.text);
                                      if(nameButton == 'SALVAR')
                                      {
                                        double cleanAmount = moneyConvert.convertFromString(controller.text);
                                        double totalPrice = cleanAmount * double.parse(_qtdText.text.replaceAll(',', '.'));
                                        ITENS.CATEGORIA = _categoriaText.text;
                                        ITENS.DESCRICAO = _descricaoText.text;
                                        ITENS.MEDIDA = _unidadeText.text.toString();
                                        ITENS.PRECO = cleanAmount;
                                        ITENS.TOTAL = totalPrice;
                                        ITENS.QTD = double.parse(_qtdText.text.replaceAll(',', '.'));
                                        controllerTotal.text = totalPrice.toStringAsFixed(2);
                                        await SaveItensInPriceList(ITENS).then((value) async => {
                                          if(Orcamento.fromListItem == true){
                                               ITENS.id = value,
                                               await db.salvaItensList(ITENS).then((value) => {
                                            })
                                          },
                                          notification(context, "Feito!", "Item adicionado com sucesso!"),
                                        });
                                      }
                                      else if(nameButton == 'ATUALIZAR' && fieldVisible == false)
                                      {
                                           ITENS.CATEGORIA = _categoriaText.text;
                                           ITENS.DESCRICAO = _descricaoText.text;
                                           ITENS.MEDIDA = _unidadeText.text.toString();
                                           ITENS.PRECO = cleanAmount;
                                           ITENS.QTD = 0;
                                           await UpadateItensInPriceList(ITENS).then((value) => {
                                               notification(context, "Feito!", "Item atualizado com sucesso!"),
                                           });
                                      }
                                      else if(nameButton == 'ATUALIZAR' && fieldVisible == true)
                                      {
                                        double cleanAmount = moneyConvert.convertFromString(controller.text);
                                        double totalPrice = cleanAmount * double.parse(_qtdText.text.replaceAll(',', '.'));
                                        ITENS.CATEGORIA = _categoriaText.text;
                                        ITENS.DESCRICAO = _descricaoText.text;
                                        ITENS.MEDIDA = _unidadeText.text.toString();
                                        ITENS.PRECO = cleanAmount;
                                        ITENS.QTD = double.parse(_qtdText.text.replaceAll(',', '.'));
                                        controllerTotal.text = totalPrice.toStringAsFixed(2);
                                        ITENS.TOTAL = totalPrice;
                                        await UpdateItensOrcamentoList(ITENS).then((value) => {
                                          notification(context, "Feito!", "Item atualizado com sucesso!"),
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