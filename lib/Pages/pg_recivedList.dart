import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Models/Db.dart';
import 'package:oflite/Pages/pg_createPayment.dart';
import 'package:oflite/Pages/pg_generateRecived.dart';
import 'package:oflite/Pages/pg_tabRecibos.dart';
import 'package:oflite/constants.dart';
import '../Models/convert_coin.dart';
import '../Objetos/DADOS.dart';
import '../Objetos/ObjectPagamentosCliente.dart';
import '../Objetos/ObjectRecived.dart';
import '../Services/display_alert.dart';
import '../Services/loading_event.dart';
import '../anmition/fadeanimation.dart';
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;

TextEditingController _descricaoText = TextEditingController();

class PgRecivedList extends StatefulWidget {
  final DADOS item;
  const PgRecivedList({Key? key, required this.item}) : super(key: key);
  @override
  _PgRecivedList createState() => _PgRecivedList();
}

enum Gender{
  comentText,
}

class _PgRecivedList extends State<PgRecivedList> {
  var displayAlert = DisplayAlert();
  var db = Db();
  var foundPayment = <Recived>[];
  var deleteItems = <Recived>[];
  convert_coin moneyConvert = convert_coin();
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  var loadingEvent = LoadingEvent();

  Future<void> inicialData()async {
    foundPayment = await db.getListRecived();
    setState(() {});
  }

  @override
  initState() {
    super.initState();
    setState(() {
      inicialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              height: he * 0.07,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                GestureDetector(
                  onTap: (){
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: we * 0.02),
                    child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: he * 0.03,
            ),
            FadeAnimation(
              delay: 1,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.028),
                child: Text("Recibos",style: GoogleFonts.heebo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    letterSpacing: 2
                ),
                ),
              ),
            ),
            SizedBox(
              height: he * 0.03,
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.cyan[50],
                backgroundColor: bgColor,
                onRefresh: () async {
                  setState(() {
                    inicialData();
                  });
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 150, left: 15, right: 15, top: 10),
                  itemCount: foundPayment.length,
                  itemBuilder: (context, index) {
                    return  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child:
                      Theme(
                        data: Theme.of(context).copyWith(unselectedWidgetColor: bgColor),
                        child: ExpansionTileCard(
                          expandedTextColor: bgColor,
                          baseColor: Colors.cyan[50],
                          expandedColor: Colors.blue[50],
                          leading: const CircleAvatar(
                              backgroundColor: bgColor,
                              child: Icon(Icons.receipt_long_rounded, color: Colors.white,)),
                          title:
                          Text(
                            foundPayment[index].DESCRICAO!,
                            maxLines: 2,
                            style: const TextStyle(
                              color: bgColor,
                              letterSpacing: 0.5,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Valor total do recibo: ${moneyConvert.convertFromDouble(foundPayment[index].VALORTOTAL!)}",
                            style: const TextStyle(
                              color: bgColor,
                              letterSpacing: 0.5,
                              fontSize: 12.0,
                            ),
                          ),
                          children: <Widget>[
                            const Divider(
                              thickness: 1.0,
                              height: 1.0,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 5.0,
                                ),
                                child: Text(
                                  "Data do recibo: ${foundPayment[index].DATA}",
                                  style: const TextStyle(
                                    color: bgColor,
                                    letterSpacing: 0.5,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                  vertical: 5.0,
                                ),
                                child: Text(
                                  "Quantidade: ${foundPayment[index].ID}",
                                  style: const TextStyle(
                                    color: bgColor,
                                    letterSpacing: 0.5,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5, top: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      return Visibility(
                                        visible: true,
                                        maintainSize: true,
                                        maintainAnimation: true,
                                        maintainState: true,
                                        child: SizedBox(
                                          width: 85.0,
                                          height: 52.0,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: bgColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5.0),
                                              ),
                                            ),
                                            onPressed: () async {
                                              try {
                                                loadingEvent.alertLoading(context);
                                                await db.deleteRecived(foundPayment[index]).then((value) => {
                                                  loadingEvent.closeLoading(context),
                                                  displayAlert.notificationNotCloseScreen(context, "Feito!", "Recibo removido com sucesso!").then((value) => {
                                                    setState(() {
                                                      inicialData();
                                                    }),
                                                  }),
                                                });
                                              } catch (e){
                                                loadingEvent.closeLoading(context);
                                                await displayAlert.notificationError(context, "Erro!", "Problemas para remover o recibo!");
                                              }
                                            },
                                            child: const Column(
                                              children: <Widget>[
                                                SizedBox(height: 4),
                                                Icon(Icons.delete_outline_rounded),
                                                SizedBox(height: 2.0),
                                                Text('Excluir'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  LayoutBuilder(
                                    builder: (BuildContext context, BoxConstraints constraints) {
                                      return SizedBox(
                                        width: 85.0,
                                        height: 52.0,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: bgColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PageTabRecibos(item: widget.item, recibos: foundPayment[index]),
                                              ),
                                            ).then((value) async => {
                                              setState(() {
                                                 inicialData();
                                              }),
                                            });
                                          },
                                          child: const Column(
                                            children: <Widget>[
                                              SizedBox(height: 4),
                                              Icon(Icons.open_in_new_rounded),
                                              SizedBox(height: 2.0),
                                              Text('Abrir'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ]
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Recived ITENS = Recived();
          ITENS.DATA = '';
          ITENS.ID = '';
          ITENS.DESCRICAO = 'null';
          ITENS.VALORTOTAL = 0;
          Orcamento.IDRECIBO = DateTime.now().millisecondsSinceEpoch.toString();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PageTabRecibos(item: widget.item, recibos: ITENS,)),
          ).then((value) async => {
            setState(() {
              inicialData();
            }),
          });
        },
        backgroundColor: buttonColor,
        child: const Icon(
          Icons.add,
          color: Colors.black,
        ),
      ),
    );
  }
}
