import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:oflite/models/observation_budget.dart';
import 'package:oflite/common/constants/constants.dart';
import '../../common/widgets/anmition/fade_animation_widget.dart';
import '../../models/customer_info.dart';
import '../../Services/display_alert.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;

TextEditingController _descricaoText = TextEditingController();

class CommentListView extends StatefulWidget {
  final CustomerInfo item;
  const CommentListView({Key? key, required this.item}) : super(key: key);

  @override
  State<CommentListView> createState() => _CommentListView();
}

enum Gender{
  commentText,
}

class _CommentListView extends State<CommentListView> {
  var observation = <ObservationBudget>[];
  var displayAlert = DisplayAlert();
  var foundObservation = <ObservationBudget>[];
  var deleteItems = <ObservationBudget>[];
  ObservationBudget novo = ObservationBudget();
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  Gender? selected;
  bool deleteVisible = false;
  bool checkBoxAppear = false;

  @override
  initState() {
    try{
         setState(()  async {
            await getListComment().then((value) => {
                  setState(() {
                    foundObservation = observation;
                  }),
            });
         });

    }
    catch (e){
      print(e);
    }
    super.initState();
  }

  Future<void> getListComment() async {
    try
    {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/OBSERVACAO")
          .get();

      querySnapshot.docs.map<ObservationBudget>((doc) {
        final objectComment = ObservationBudget.fromMap(doc.data()!);
        objectComment.id = doc.id;
        objectComment.checkbox = false;
        observation.add(objectComment);
        return objectComment;
      }).toList();
    } catch (e){
      await displayAlert.notificationError(context, "Erro!", "Não foi possível carregar os comentários");
    }
  }

  Future<void> addComment() async {
    try
    {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/OBSERVACAO")
          .doc()
          .set({'OBSERVACAO': _descricaoText.text, 'DATA': formatted
      });
    }
    catch (e){
     await displayAlert.notificationError(context, "Erro!", "Não foi possível adicionar o comentário");
    }
  }

  Future<void> addNewComment(ObservationBudget popupObservation) {
    _descricaoText.text = popupObservation.observacao!;
    String textBottonName;
    if(popupObservation.id!.isEmpty)
    {
      textBottonName = "ADICIONAR";
    }
    else
    {
      textBottonName = "ATUALIZAR";
    }
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(19),
          backgroundColor: bgColor,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: he * 0.5,
                width: we,
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              Navigator.pop(context, true);
                            });
                          },
                          child: Container(
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.only(left: we * 0.0),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 30.0,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: we * 0.25),
                          child: Text(
                            "Comentário",
                            style: GoogleFonts.heebo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: he * 0.02,
                    ),
                    Container(
                      width: we * 0.80,
                      height:he * 0.35,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: secondaryColor, width: 2),
                          color: selected == Gender.commentText ? enabled : bgColor
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _descricaoText,
                        keyboardType: TextInputType.multiline,
                        maxLines: 50,
                        onTap: (){
                          setState(() {
                            selected = Gender.commentText;
                          });
                        },
                        decoration: InputDecoration(
                            enabledBorder: InputBorder.none,
                            border:InputBorder.none,
                            hintText: 'Escreva o comentário...',
                            hintStyle: TextStyle(
                                color: selected == Gender.commentText ? enabledtxt : deaible
                            )
                        ),
                        style:  TextStyle(color: selected == Gender.commentText ? enabledtxt : deaible,fontWeight:FontWeight.bold),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 16.5)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: TextButton(
                          onPressed: () async {
                            if(popupObservation.id!.isEmpty)
                            {
                              await addComment().then((value) async => {
                                foundObservation.clear(),
                                observation.clear(),
                                await getListComment().then((value) => {
                                  setState(() async {
                                    deleteItems.clear();
                                    deleteVisible = false;
                                    checkBoxAppear = false;
                                    await displayAlert.notification(context, "Feito!", "Cometário adicionado com sucesso!");
                                  }),
                                }),
                              });
                            }
                            else
                            {
                              popupObservation.observacao = _descricaoText.text;
                              await updateComment(popupObservation).then((value) => {
                                setState(() async {
                                  await displayAlert.notification(context, "Feito!", "Cometário atualizado com sucesso!");
                                }),
                              });
                            }
                          },
                          style: TextButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 90),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0)
                              )
                          ),
                          child: Text(textBottonName,style: GoogleFonts.heebo(
                            color: Colors.black,
                            letterSpacing: 0,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          )
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((value) async {
      foundObservation.clear();
      observation.clear();
      await getListComment();
      setState(() {
        deleteItems.clear();
        deleteVisible = false;
        checkBoxAppear = false;
      });
    });
  }

  Future<void> updateComment(ObservationBudget updateObservation) async {
    try {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/OBSERVACAO")
          .doc(updateObservation.id)
          .update({'OBSERVACAO': updateObservation.observacao, 'DATA': updateObservation.data
      });
    } catch (e) {
      await displayAlert.notificationError(context, "Erro!", "Não foi possível atualizar o comentário");
    }
  }

  Future <bool> deleteData() async {
    try{
      bool result = false;
      int count = deleteItems.length - 1;
      for(int i = 0; i< deleteItems.length; i++)
      {
        await FirebaseFirestore.instance
            .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS/${widget.item.id}/OBSERVACAO")
            .doc(deleteItems[i].id)
            .delete().then((value) async {
          if(i == count)
          {
            deleteItems.clear();
            observation.clear();
            deleteVisible = false;
            await getListComment();
            setState(() {});
          }
        });
      }
      return result;

    }catch (e){
      await displayAlert.notificationError(context, "Erro!", "Não foi possível remover o comentário");
      return false;
    }
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
                child: Text("Comentários",style: GoogleFonts.heebo(
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
                  foundObservation.clear();
                  observation.clear();
                  await getListComment();
                  setState(() {
                    deleteItems.clear();
                    deleteVisible = false;
                    checkBoxAppear = false;
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
                      data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                      child: ExpansionTileCard(
                        expandedTextColor: whiteColor,
                        baseColor: secondaryColor,
                        expandedColor: secondaryColor,
                        leading: const CircleAvatar(
                            backgroundColor: bgColor,
                            child: Icon(Icons.comment, color: whiteColor,)),
                        title:
                        Text(
                          "${foundObservation[index].observacao}",
                          maxLines: 2,
                          style: const TextStyle(
                            color: whiteColor,
                            letterSpacing: 0.5,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Data: ${foundObservation[index].data}",
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
                                "Comentário: ${foundObservation[index].observacao}",
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
                                      visible: !foundObservation[index].checkbox!,
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
                                            deleteItems.add(foundObservation[index]);
                                            await deleteData();
                                            deleteItems.clear();
                                            deleteVisible = false;
                                            checkBoxAppear = false;
                                            setState(() {});
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
                                        onPressed: () async {
                                          await addNewComment(foundObservation[index]);
                                        },
                                        child: const Column(
                                          children: <Widget>[
                                            SizedBox(height: 4),
                                            Icon(Icons.edit, color: bgColor),
                                            SizedBox(height: 2.0),
                                            Text('Editar', style: TextStyle(fontSize: 8.5, color: bgColor)),
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
          var newObservation = ObservationBudget();
          newObservation.checkbox = false;
          newObservation.id = '';
          newObservation.data = '';
          newObservation.uid = '';
          newObservation.observacao = '';
          addNewComment(newObservation);
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
