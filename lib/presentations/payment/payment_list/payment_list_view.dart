import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:oflite/common/widgets/anmition/fade_animation_widget.dart';
import 'package:oflite/models/receipt.dart';
import 'package:oflite/presentations/payment/payment_creator/payment_creator_view.dart';
import 'package:oflite/common/constants/constants.dart';
import '../../../services/convert_coin.dart';
import '../../../models/customer_info.dart';
import '../../../models/payment_customer.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';
import 'package:oflite/models/global_uid_budget.dart' as Orcamento;

class PaymentListView extends StatefulWidget {
  final CustomerInfo item;
  final Receipt recibos;
  const PaymentListView({Key? key, required this.item, required this.recibos}) : super(key: key);

  @override
  State<PaymentListView> createState() => _PaymentListView();
}

enum Gender{
  comentText,
}

class _PaymentListView extends State<PaymentListView> {
  var displayAlert = DisplayAlert();
  var db = HttpRequest();
  var loadingEvent = LoadingEvent();
  var foundPayment = <PaymentCustomer>[];
  var deleteItems = <PaymentCustomer>[];
  ConvertCoin moneyConvert = ConvertCoin();
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;

  Future<void> inicialData()async {
    foundPayment = await db.getListPayment(widget.recibos, widget.item);
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
                child: Text("Pagamentos",style: GoogleFonts.heebo(
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
                              child: Icon(Icons.payments_outlined, color: whiteColor,)),
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
                            "Valor do pagamento: ${moneyConvert.convertFromDouble(foundPayment[index].PRECO!)}",
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
                                  "Método do pagamento: ${foundPayment[index].METODO}",
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
                                              loadingEvent.alertLoading(context);
                                              try{
                                                await db.deletePaymentCustomer(foundPayment[index].id!).then((value) async => {
                                                  loadingEvent.closeLoading(context),
                                                  await displayAlert.notificationNotCloseScreen(context, "Feito!", "Pagamento removido com sucesso!"),
                                                });
                                              }
                                              catch (e) {
                                                loadingEvent.closeLoading(context);
                                                await displayAlert.notificationError(context, "Erro!", "Problemas para remover o pagamento");
                                              }

                                              setState(() {
                                                inicialData();
                                              });
                                            },
                                            child: const Column(
                                              children: <Widget>[
                                                SizedBox(height: 4),
                                                Icon(Icons.delete_outline_rounded, color: bgColor),
                                                SizedBox(height: 2.0),
                                                Text('Editar', style: TextStyle(fontSize: 10, color: bgColor)),
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
                                          onPressed: () async {
                                            Orcamento.IDRECIBO = widget.recibos.ID;
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => PaymentCreatorView(item: foundPayment[index])),
                                            ).then((value) async => {
                                               setState(() {
                                                 inicialData();
                                               }),
                                            });
                                          },
                                          child: const Column(
                                            children: <Widget>[
                                              SizedBox(height: 4),
                                              Icon(Icons.edit, color: bgColor),
                                              SizedBox(height: 2.0),
                                              Text('Editar', style: TextStyle(fontSize: 10, color: bgColor)),
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
          PaymentCustomer ITENS = PaymentCustomer();
          ITENS.METODO = '';
          ITENS.id = '';
          ITENS.DESCRICAO = 'null';
          ITENS.PRECO = 0;
          Orcamento.IDRECIBO = widget.recibos.ID;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentCreatorView(item: ITENS)),
          ).then((value) async => {
            setState(() {}),
          }).then((value) => {
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
      bottomNavigationBar: BottomAppBar(
        color: buttonColor,
        elevation: 0,
        child: Container(
          height: 65.0,
          color: buttonColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "Total pago: ${moneyConvert.convertFromDouble(widget.recibos.VALORTOTAL!)}",
                  style: const TextStyle(color: bgColor, fontWeight: FontWeight.bold,),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
