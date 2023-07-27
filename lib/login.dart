import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/constants.dart';
import 'package:oflite/singup.dart';
import 'Services/display_alert.dart';
import 'Services/loading_event.dart';
import 'anmition/fadeanimation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/Objetos/ObjetoUIDUser.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

TextEditingController _emailText = TextEditingController();
TextEditingController _passwordText = TextEditingController();

enum Gender{
  email,
  password,
}

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _Login();
}

class _Login extends State<Login> {
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool ispasswordev = true;
  Gender? selected;
  late String uid;
  final displayAlert = DisplayAlert();
  ObjetoUIDUser users = ObjetoUIDUser();
  final alertDisplayLoading = LoadingEvent();
  late List<PurchasedItem>? resultSubscription = [];

  final List<String> _productLists = Platform.isAndroid
      ? [
    'newproduct',
  ] : ['com.housestudio.oflite', 'com.housestudio.oflite'];


  @override
  void initState() {
    super.initState();
    asyncInitState();
    checkAutoLogin();
  }

  void asyncInitState() async {
    await FlutterInappPurchase.instance.initialize();
    await FlutterInappPurchase.instance.getSubscriptions(_productLists);
  }

  void checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    if (email != null && password != null) {
      try
      {
        alertDisplayLoading.alertLoading(context);
        await _emailAndPassword(email, password);
      }catch(e){
        alertDisplayLoading.closeLoading(context);
      }
    } else {
    }
  }

  Future<void> _emailAndPassword(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
     ).then((value) async => {
          await prefs.setString('email', email),
          await prefs.setString('password', password),
          UID.Senha = password.trim(),
          uid = value.user!.uid.toString(),
          await getUserInfo().then((value) => {

          }),
     });
  }

  Future<ObjetoUIDUser> getContacts() async {
    return users;
  }

  Future<ObjetoUIDUser> getUserInfo() async {
        FirebaseFirestore.instance
        .collection('USUARIOS')
        .where('USER', isEqualTo: uid)
        .get().then((value) async {
             value.docs.forEach((element) async {
               Map<String, dynamic> obj = element.data();
                 users.USER = obj['USER'];
                 users.NOME = obj['NOME'];
                 users.EMAIL = obj['EMAIL'];
                 users.FONE = obj['FONE'];
                 users.Id = obj['Id'];
                 users.IdPay = obj['IdPay'];
                 users.ProductId = obj['ProductId'];
                 users.PurchaseToken = obj['PurchaseToken'];
                 users.AutoRenewing = obj['AutoRenewing'];
                 UID.USER = obj['USER'];
                 UID.NOME = obj['NOME'];
                 UID.EMAIL = obj['EMAIL'];
                 UID.FONE = obj['FONE'];
                 UID.Id = obj['Id'];
                 UID.IdPay = obj['IdPay'];
                 UID.ProductId = obj['ProductId'];
                 UID.PurchaseToken = obj['PurchaseToken'];
                 UID.AutoRenewing = obj['AutoRenewing'];

                 resultSubscription  = await FlutterInappPurchase.instance.getAvailablePurchases();
                 if(resultSubscription!.isNotEmpty){
                   var latestSubscription = resultSubscription!.reduce((current, next) =>
                   current.transactionDate!.millisecondsSinceEpoch > next.transactionDate!.millisecondsSinceEpoch
                       ? current
                       : next);

                   Map<String, dynamic> data = jsonDecode(latestSubscription!.transactionReceipt ?? '');
                   bool acknowledgedValue = data['acknowledged'];
                   UID.AutoRenewing = data['autoRenewing'];
                   UID.PurchaseToken = data['purchaseToken'];
                   UID.ProductId = data['productId'];

                    if(!acknowledgedValue) {
                        await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(latestSubscription.purchaseToken ?? '');
                      }
                 }
                 else
                 {
                     UID.AutoRenewing = false;
                     UID.PurchaseToken = '';
                 }

             });
             alertDisplayLoading.closeLoading(context);
             Navigator.pushReplacementNamed(context, '/menu');
        });
        return users;
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery
        .of(context)
        .size
        .width;
    var he = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Column(
              children: <Widget>[
                FadeAnimation(delay: 0.8,
                  child: CachedNetworkImage(
                    imageUrl: "https://cdni.iconscout.com/illustration/premium/thumb/job-starting-date-2537382-2146478.png",
                    width: we * 0.9,
                    height: he * 0.4,),),
                FadeAnimation(
                  delay: 1,
                  child: Container(
                    margin: const EdgeInsets.only(right: 230.0),
                    child: Text("Entrar", style: GoogleFonts.heebo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 35,
                        letterSpacing: 2
                    ),
                    ),
                  ),
                ),
                SizedBox(
                  height: he * 0.01,
                ),
                SizedBox(
                  height: he * 0.04,
                ),
                FadeAnimation(
                  delay: 1,
                  child: Container(
                    width: we * 0.9,
                    height: he * 0.071,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: selected == Gender.email
                          ? enabled
                          : bgColor,
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
                ),
                SizedBox(
                  height: he * 0.02,
                ),
                FadeAnimation(
                  delay: 1,
                  child: Container(
                    width: we * 0.9,
                    height: he * 0.071,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: selected == Gender.password
                            ? enabled
                            : bgColor
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _passwordText,
                      onTap: () {
                        setState(() {
                          selected = Gender.password;
                        });
                      },
                      decoration: InputDecoration(
                          enabledBorder: InputBorder.none,
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.lock_open_outlined,
                            color: selected == Gender.password
                                ? enabledtxt
                                : deaible,),
                          suffixIcon: IconButton(
                            icon: ispasswordev ? Icon(Icons.visibility_off,
                              color: selected == Gender.password
                                  ? enabledtxt
                                  : deaible,) : Icon(Icons.visibility,
                              color: selected == Gender.password
                                  ? enabledtxt
                                  : deaible,),
                            onPressed: () =>
                                setState(() => ispasswordev = !ispasswordev),
                          ),
                          hintText: 'Senha',
                          hintStyle: TextStyle(
                              color: selected == Gender.password
                                  ? enabledtxt
                                  : deaible
                          )
                      ),
                      obscureText: ispasswordev,
                      style: TextStyle(color: selected == Gender.password
                          ? enabledtxt
                          : deaible, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  height: he * 0.02,
                ),
                FadeAnimation(
                  delay: 1,
                  child: TextButton(
                      onPressed: () async {
                        try
                        {
                          alertDisplayLoading.alertLoading(context);
                          await _emailAndPassword(_emailText.text, _passwordText.text);
                        } catch(e){
                          alertDisplayLoading.closeLoading(context);
                          displayAlert.notificationError(context, "Erro!", "Problemas para realizar seu login verifique sua senha e e-mail");
                        }
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 80),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)
                          )
                      ),
                      child: Text("Entrar", style: GoogleFonts.heebo(
                        color: Colors.black,
                        letterSpacing: 0.5,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      )
                  ),
                ),
                SizedBox(
                  height: he * 0.01,
                ),
                FadeAnimation(
                  delay: 1,
                  child: TextButton(
                      onPressed: () async {
                        displayAlert.dialogChangePassword(context);
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: bgColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 80),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)
                          )
                      ),
                      child: Text("Esqueceu sua senha?", style: GoogleFonts.heebo(
                        color: buttonColor,
                        letterSpacing: 0.5,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                      )
                  ),
                ),
                SizedBox(
                    height: he * 0.12
                ),
                FadeAnimation(
                  delay: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Quer se cadastrar? ", style: GoogleFonts.heebo(
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      )),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) {
                                return const Singup();
                              }
                              )).then((_) {
                                  checkAutoLogin();
                              });
                        },
                        child: Text("Clique aqui", style: GoogleFonts.heebo(
                          color: buttonColor.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        )),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
    );
  }}
