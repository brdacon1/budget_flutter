import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/services/http_request.dart';
import 'package:oflite/common/constants/constants.dart';
import '../../common/widgets/anmition/fade_animation_widget.dart';
import '../singup/singup_view.dart';
import '../terms_conditions/terms_conditions_view.dart';
import '../../Services/display_alert.dart';
import '../../Services/loading_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/models/info_user.dart';
import 'package:oflite/models/global_uid_user.dart' as global_uid_user;
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

TextEditingController _emailText = TextEditingController();
TextEditingController _passwordText = TextEditingController();

enum Gender{
  email,
  password,
}

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginView();
}

class _LoginView extends State<LoginView> {
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool ispasswordev = true;
  Gender? selected;
  late String uid;
  final displayAlert = DisplayAlert();
  InfoUser users = InfoUser();
  var db = HttpRequest();
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

    if (email != null && password != "NO_PASS") {
      try
      {
        alertDisplayLoading.alertLoading(context);
        await _emailAndPassword(email, password!);
      }catch(e){
        alertDisplayLoading.closeLoading(context);
      }
    } else {
    }
  }

  Future<void> _signinWithGoogle() async {
    GoogleSignInAuthentication? googleAuth;
    AuthCredential credential;
    var googleUser = await GoogleSignIn().signIn();
    googleAuth = await googleUser?.authentication;
    credential = GoogleAuthProvider.credential(
              accessToken: googleAuth?.accessToken,
              idToken: googleAuth?.idToken,
    );
    await singWithCredential(credential);
  }

  Future<void> singWithCredential(AuthCredential credential) async {
    alertDisplayLoading.alertLoading(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var auth = await _auth.signInWithCredential(credential);
    await prefs.setString('email', auth.user?.email ?? '');
    await prefs.setString('password', 'NO_PASS');
    global_uid_user.password = 'NO_PASS';
    global_uid_user.googleAuth = true;
    uid = auth.user?.uid ?? '';
    var USER = await getUserInfo();
    if(USER.USER != auth.user!.uid) {
      await db.createUserWithGoogle(auth.user, context).then((value) => {
        alertDisplayLoading.closeLoading(context),
        Navigator.pushReplacementNamed(context, '/menu'),
      });
    } else {
       alertDisplayLoading.closeLoading(context);
       await Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  Future<void> _emailAndPassword(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
     var auth = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
     );
     await prefs.setString('email', email);
     await prefs.setString('password', password);
     global_uid_user.password = password.trim();
     uid = auth.user!.uid.toString();
     var USER = await getUserInfo();
     global_uid_user.googleAuth = false;
    if(USER.USER !=  null) {
      alertDisplayLoading.closeLoading(context);
      await Navigator.pushReplacementNamed(context, '/menu');
    }

  }

  Future<InfoUser> getContacts() async {
    return users;
  }

  Future<InfoUser> getUserInfo() async {
      await  FirebaseFirestore.instance
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
                 users.AutoRenewing = obj['AutoRenewing'] ?? false;
                 global_uid_user.user = obj['USER'];
                 global_uid_user.name = obj['NOME'] ?? 'User';
                 global_uid_user.email = obj['EMAIL'];
                 global_uid_user.phone = obj['FONE'];
                 global_uid_user.id = obj['Id'];
                 global_uid_user.idPay = obj['IdPay'];
                 global_uid_user.productId = obj['ProductId'];
                 global_uid_user.purchaseToken = obj['PurchaseToken'];
                 global_uid_user.autoRenewing = obj['AutoRenewing'] ?? false;
             });
        });


      resultSubscription  = await FlutterInappPurchase.instance.getAvailablePurchases();
      if(resultSubscription!.isNotEmpty){
        var latestSubscription = resultSubscription!.reduce((current, next) =>
        current.transactionDate!.millisecondsSinceEpoch > next.transactionDate!.millisecondsSinceEpoch
            ? current
            : next);

        Map<String, dynamic> data = jsonDecode(latestSubscription.transactionReceipt ?? '');
        bool acknowledgedValue = data['acknowledged'];
        global_uid_user.autoRenewing = data['autoRenewing'] ?? false;
        global_uid_user.purchaseToken = data['purchaseToken'];
        global_uid_user.productId = data['productId'];
        if(!acknowledgedValue) {
          await FlutterInappPurchase.instance.acknowledgePurchaseAndroid(latestSubscription.purchaseToken ?? '');
        }
      }
      else {
        global_uid_user.autoRenewing = false;
        global_uid_user.purchaseToken = '';
      }
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
        body: Center(
         child: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: he * 0.020,
                ),
                FadeAnimationWidget(
                  delay: 0.8,
                  child:  Image.asset(
                    'assets/login-initial-page.png',
                    width: we * 0.5,
                    height: he * 0.25,
                  ),
                ),
                FadeAnimationWidget(
                  delay: 1,
                  child: Container(
                    margin: const EdgeInsets.only(right: 240.0),
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
                FadeAnimationWidget(
                  delay: 1,
                  child: Container(
                    width: we * 0.9,
                    height: he * 0.082,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor, width: 2),
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
                FadeAnimationWidget(
                  delay: 1,
                  child: Container(
                    width: we * 0.9,
                    height: he * 0.082,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: secondaryColor, width: 2),
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
                FadeAnimationWidget(
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
                FadeAnimationWidget(
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
                    height: he * 0.02
                ),
                FadeAnimationWidget(
                  delay: 1,
                  child: TextButton(
                      onPressed: () async {
                        _signinWithGoogle();
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 80),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)
                          )
                      ),
                      child: Text("Login com Google", style: GoogleFonts.heebo(
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      )
                  ),
                ),
                SizedBox(
                    height: he * 0.025
                ),
                FadeAnimationWidget(
                  delay: 1,
                  child: TextButton(
                      onPressed: () async {
                         await  Navigator.of(context).push(
                             MaterialPageRoute(builder: (context) {
                               return TermsConditionsView();
                             }
                             ));
                      },
                      style: TextButton.styleFrom(
                          backgroundColor: bgColor,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 80),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)
                          )
                      ),
                      child: Text("Politica de privacidade", style: GoogleFonts.heebo(
                        color: buttonColor,
                        letterSpacing: 0.5,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                ),
              ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: bgColor,
        elevation: 0,
        child: Container(
          height: 65.0,
          color: bgColor,
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
                        return const SingUpView();
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
        ),
      ),
    );
  }
}
