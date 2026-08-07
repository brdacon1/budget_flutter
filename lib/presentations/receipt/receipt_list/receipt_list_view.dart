import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/presentations/receipt/receipt_tab/receipt_tab_view.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/common/constants/constants.dart';
import '../../../common/widgets/anmition/fade_animation_widget.dart';
import '../../../services/convert_coin.dart';
import '../../../models/customer_info.dart';
import '../../../models/receipt.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;


class ReceiptListView extends StatefulWidget {
  final CustomerInfo item;
  const ReceiptListView({Key? key, required this.item}) : super(key: key);


  @override
  State<ReceiptListView> createState() => _ReceiptListView();
}

enum Gender{
  commentText,
}

class _ReceiptListView extends State<ReceiptListView> {
  var displayAlert = DisplayAlert();
  var db = HttpRequest();
  var foundPayment = <Receipt>[];
  var deleteItems = <Receipt>[];
  ConvertCoin moneyConvert = ConvertCoin();
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  Color enabled = const Color(0xFF827F8A);
  Color enabletxt = Colors.white;
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
            FadeAnimationWidget(
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
                        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                        child: ExpansionTileCard(
                          expandedTextColor: whiteColor,
                          baseColor: secondaryColor,
                          expandedColor: secondaryColor,
                          leading: const CircleAvatar(
                              backgroundColor: bgColor,
                              child: Icon(Icons.receipt_long_rounded, color: whiteColor,)),
                          title:
                          Text(
                            foundPayment[index].DESCRICAO!,
                            maxLines: 2,
                            style: const TextStyle(
                              color: whiteColor,
                              letterSpacing: 0.5,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Valor total do recibo: ${moneyConvert.convertFromDouble(foundPayment[index].VALORTOTAL!)}",
                            style: const TextStyle(
                              color: whiteColor,
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
                                    color: whiteColor,
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
                                    color: whiteColor,
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
                                              backgroundColor: whiteColor,
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
                                                Icon(Icons.delete_outline_rounded, color: bgColor,),
                                                SizedBox(height: 2.0),
                                                Text('Excluir', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
                                            backgroundColor: whiteColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ReceiptTabView(item: widget.item, receipt: foundPayment[index]),
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
                                              Icon(Icons.open_in_new_rounded, color: bgColor,),
                                              SizedBox(height: 2.0),
                                              Text('Abrir', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
          Receipt ITENS = Receipt();
          ITENS.DATA = '';
          ITENS.ID = '';
          ITENS.DESCRICAO = 'null';
          ITENS.VALORTOTAL = 0;
          budget.IDRECIBO = DateTime.now().millisecondsSinceEpoch.toString();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReceiptTabView(item: widget.item, receipt: ITENS,)),
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
