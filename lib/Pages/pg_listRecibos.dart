import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oflite/Objetos/ObjectObservation.dart';
import 'package:oflite/constants.dart';
import '../Objetos/DADOS.dart';
import '../Services/display_alert.dart';
import '../anmition/fadeanimation.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;

TextEditingController _descricaoText = TextEditingController();

class ListRecibosPage extends StatefulWidget {
  final DADOS item;
  const ListRecibosPage({Key? key, required this.item}) : super(key: key);
  @override
  _ListRecibosPage createState() => _ListRecibosPage();
}

enum Gender{
  comentText,
}

class _ListRecibosPage extends State<ListRecibosPage> {
  var observation = <ObjectObservation>[];
  var displayAlert = DisplayAlert();
  var foundObservation = <ObjectObservation>[];
  var deleteItems = <ObjectObservation>[];
  ObjectObservation novo = ObjectObservation();
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;

  @override
  initState() {
    try{
    }
    catch (e){
      print(e);
    }
    super.initState();
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

                  });
                },
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 150, left: 15, right: 15, top: 10),
                  itemCount: foundObservation.length,
                  itemBuilder: (context, index) {
                    return  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Theme(
                        data: Theme.of(context).copyWith(unselectedWidgetColor: bgColor),
                        child: ExpansionTileCard(
                          expandedTextColor: bgColor,
                          baseColor: Colors.cyan[50],
                          expandedColor: Colors.blue[50],
                          leading: const CircleAvatar(
                              backgroundColor: bgColor,
                              child: Icon(Icons.comment, color: Colors.white,)),
                          title:
                          Text(
                            "${foundObservation[index].observacao}",
                            maxLines: 2,
                            style: const TextStyle(
                              color: bgColor,
                              letterSpacing: 0.5,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "Data: ${foundObservation[index].data}",
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
                                  "Comentário: ${foundObservation[index].observacao}",
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
                                        visible: !foundObservation[index].checkbox!,
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
                                              deleteItems.add(foundObservation[index]);

                                              deleteItems.clear();
                                              deleteVisible = false;
                                              checkBoxAppear = false;
                                              setState(() {});
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
                                          onPressed: () async {

                                          },
                                          child: const Column(
                                            children: <Widget>[
                                              SizedBox(height: 4),
                                              Icon(Icons.edit),
                                              SizedBox(height: 2.0),
                                              Text('Editar'),
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
        onPressed: () {
          var newObservation = ObjectObservation();
          newObservation.checkbox = false;
          newObservation.id = '';
          newObservation.data = '';
          newObservation.uid = '';
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
