import 'dart:async';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Models/Db.dart';
import '../Objetos/ObjetoUIDUser.dart';
import '../constants.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as globalUIDUser;

import 'loading_event.dart';

TextEditingController _emailText = TextEditingController();
TextEditingController _nameText = TextEditingController();
final FirebaseAuth _auth = FirebaseAuth.instance;

enum Gender{
  email,
  name,
}


class DisplayAlert {
  var db = Db();
  var DADOS = ObjetoUIDUser();
  var alertDisplayLoading = LoadingEvent();


  Future<void> notificationError(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        animType: AnimType.leftSlide,
        headerAnimationLoop: false,
        dialogType: DialogType.error,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
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
        btnOkOnPress: () => completer.complete(),
        btnOkIcon: Icons.check_circle,
      ).show();
    });

    return completer.future;
  }

  Future<void> notificationWarning(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        animType: AnimType.leftSlide,
        headerAnimationLoop: false,
        dialogType: DialogType.warning,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
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
        btnOkOnPress: () => completer.complete(),
        btnOkIcon: Icons.check_circle,
      ).show();
    });

    return completer.future;
  }


  Future<void> dialogChangePassword(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    Color enabled = const Color(0xFF827F8A);
    Color enabledtxt = Colors.white;
    Color deaible = Colors.grey;
    Gender? selected;

    _emailText.text = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(19),
          backgroundColor: bgColor,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: he * 0.26,
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
                          margin: EdgeInsets.only(right: we * 0.1),
                          child: Text(
                            "Recuperação de senha",
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
                      height: he * 0.035,
                    ),
                    Container(
                      width: we * 0.80,
                      height:he * 0.082,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: secondaryColor, width: 2),
                          color: selected == Gender.email ? enabled : bgColor
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _emailText,
                        onTap: () {
                          setState(() {
                            selected = Gender.email;
                          });
                        },
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email_outlined,
                            color: selected == Gender.email
                                ? enabledtxt
                                : deaible,),
                          hintText: 'E-mail',
                          hintStyle: TextStyle(
                            color: selected == Gender.email
                                ? enabledtxt
                                : deaible,
                          ),
                        ),
                        style: TextStyle(color: selected == Gender.email
                            ? enabledtxt
                            : deaible, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 25),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TextButton(
                          onPressed: () async {
                            try
                            {
                              await _auth.sendPasswordResetEmail(
                                email: _emailText.text.trim(),
                              ).then((value) async => {
                                notification(context, "Feito!", "Você recebeu um email para trocar de senha")
                              });
                            }
                            catch (e){
                             await notificationError(context, "Erro!", "Problemas para restaurar sua senha verifique seu e-email se está correto!");
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 70,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: Text(
                            "Solicitar senha",
                            style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((value) async {

    });
  }

  Future<void> dialogChangeName(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    Color enabled = const Color(0xFF827F8A);
    Color enabledtxt = Colors.white;
    Color deaible = Colors.grey;
    Gender? selected;

    _nameText.text = '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(19),
          backgroundColor: bgColor,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: he * 0.27,
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
                          margin: EdgeInsets.only(right: we * 0.15),
                          child: Text(
                            "Trocar nome usuário",
                            style: GoogleFonts.heebo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: he * 0.03,
                    ),
                    Container(
                      width: we * 0.80,
                      height:he * 0.082,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: secondaryColor, width: 2),
                          color: selected == Gender.name ? enabled : bgColor
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _nameText,
                        onTap: () {
                          setState(() {
                            selected = Gender.name;
                          });
                        },
                        decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person_pin_outlined,
                            color: selected == Gender.name
                                ? enabledtxt
                                : deaible,),
                          hintText: 'SEU NOME',
                          hintStyle: TextStyle(
                            color: selected == Gender.name
                                ? enabledtxt
                                : deaible,
                          ),
                        ),
                        style: TextStyle(color: selected == Gender.name
                            ? enabledtxt
                            : deaible, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: he * 0.0416,
                    ),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: TextButton(
                          onPressed: () async {
                            try
                            {
                              alertDisplayLoading.alertLoading(context);
                              if(_nameText.text.isNotEmpty){
                                DADOS.AutoRenewing = globalUIDUser.AutoRenewing;
                                DADOS.EMAIL = globalUIDUser.EMAIL;
                                DADOS.FONE = globalUIDUser.FONE;
                                DADOS.Id = globalUIDUser.Id;
                                DADOS.IdPay = globalUIDUser.IdPay;
                                DADOS.NOME = _nameText.text;
                                DADOS.ProductId = globalUIDUser.ProductId;
                                DADOS.PurchaseToken = globalUIDUser.PurchaseToken;
                                DADOS.USER = globalUIDUser.USER;

                                await db.updateUserAdm(DADOS).then((value) async => {
                                  globalUIDUser.NOME = _nameText.text,
                                  alertDisplayLoading.closeLoading(context),
                                  await notification(context, "Feito!", "Nome atualizado com sucesso!"),
                                });
                              }
                              else
                              {
                                await notificationError(context, "Erro!", "O campo nome não pode ser vazio!");
                              }

                            }
                            catch (e){
                              await notificationError(context, "Erro!", "Problemas para restaurar sua senha verifique seu e-email se está correto!");
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: buttonColor,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 70,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: Text(
                            "SALVAR",
                            style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

    });
  }

  Future<String> adsNotification(BuildContext context) async {
    List<String> values = ['Ver anuncio', 'Se tornar premium'];
    String resultText = "";
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          backgroundColor: Colors.cyan[50],
          title: const Text("Escolha uma opção", style: TextStyle(color: Colors.black),),
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
                              fontSize: 16.0)),
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
      resultText = value ?? '',
    });
    return resultText;
  }

   Future<String> listNotification(BuildContext context) async {
     List<String> values = ['Criar novo item', 'Selecionar da lista de preço'];
     String resultText = "";
     await showDialog(
         context: context,
         builder: (BuildContext context) {
       return SimpleDialog(
         backgroundColor: Colors.cyan[50],
         title: const Text("Como você quer inserir o item?", style: TextStyle(color: Colors.black),),
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
                             fontSize: 16.0)),
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
         resultText = value ?? '',
     });
     return resultText;
   }

  Future<void> notificationNotCloseScreen(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        headerAnimationLoop: false,
        dialogType: DialogType.success,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
        btnOkIcon: Icons.check_circle,
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
        btnOkOnPress: () {
          completer.complete();
        },
      ).show();
    });

    return completer.future;
  }


  Future<void> notification(BuildContext context, String firstMessage, String secondMessage) {
    final width = MediaQuery.of(context).size.width;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AwesomeDialog(
        width: width * 0.99,
        context: context,
        dialogBackgroundColor: Colors.cyan[50],
        headerAnimationLoop: false,
        dialogType: DialogType.success,
        showCloseIcon: false,
        title: firstMessage,
        desc: secondMessage,
        btnOkIcon: Icons.check_circle,
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
        btnOkOnPress: () {
          Navigator.pop(context, true);
          completer.complete();
        },
      ).show();
    });

    return completer.future;
  }
}
