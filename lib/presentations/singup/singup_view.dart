import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/widgets/anmition/fade_animation_widget.dart';
import '../../services/http_request.dart';
import '../../models/info_user.dart';
import '../../models/owner_pdf.dart';
import '../../Services/display_alert.dart';
import '../../Services/loading_event.dart';
import 'package:oflite/models/global_uid_user.dart' as globalUIDUser;
import '../login/login_view.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
TextEditingController _emailText = TextEditingController();
TextEditingController _passwordText = TextEditingController();
TextEditingController _nomeText = TextEditingController();
enum Gender{
  name,
  Email,
  password,
  confirmpassword,
  phone
}

class SingUpView extends StatefulWidget {
  const SingUpView({Key? key}) : super(key: key);

  @override
  State<SingUpView> createState() => _SingUpView();
}

class _SingUpView extends State<SingUpView> {
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool ispasswordev = true;
  Gender? selected;
  final db = HttpRequest();
  final DADOS = InfoUser();
  final PDF = OwnerPdf();
  final displayAlert = DisplayAlert();
  final alertDisplayLoading = LoadingEvent();

  Future<void> _createUserWithEmailAndPassword(String password, String email, String nome) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ).then((value) async => {
        DADOS.EMAIL = email,
        DADOS.FONE = '15991111111',
        DADOS.USER = value.user!.uid,
        DADOS.NOME = nome,
        DADOS.Id = value.user!.uid,
        PDF.email = email,
        PDF.empresa = "Minha Empresa",
        PDF.logoName = '',
        PDF.fotoId = '',
        await db.saveUserAdm(DADOS),
        await prefs.setString('email', email),
        await prefs.setString('password', password),
        globalUIDUser.user = value.user!.uid,
        globalUIDUser.name = nome,
        globalUIDUser.email = DADOS.EMAIL,
        globalUIDUser.phone = DADOS.FONE,
        globalUIDUser.id = DADOS.Id,
        globalUIDUser.idPay = "",
        globalUIDUser.productId = "",
        globalUIDUser.purchaseToken = "",
        globalUIDUser.autoRenewing = false,
        await db.savePDF(PDF).then((value) async => {
          alertDisplayLoading.closeLoading(context),
          Navigator.pop(context),
        }),
    });
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF1F1A30),
      body: SingleChildScrollView(
        child: SizedBox(
          width: we,
          height: he,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: he * 0.05,
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
                height: he * 0.03,
              ),
              FadeAnimationWidget(
                delay: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 80.0),
                  child: Text("Criar uma conta",style: GoogleFonts.heebo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 35,
                      letterSpacing: 2
                  ),
                  ),
                ),
              ),
              FadeAnimationWidget(
                delay: 1,
                child: Container(
                  margin: const EdgeInsets.only(right: 130.0),
                  child: Text("Insira suas informações abaixo",style: GoogleFonts.heebo(
                      color: Colors.grey,
                      letterSpacing: 1),
                  ),
                ),
              ),
              SizedBox(
                  height: he * 0.07
              ),
              FadeAnimationWidget(
                delay: 1,
                child: Container(
                  width: we * 0.9,
                  height:he * 0.082,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: secondaryColor, width: 2),
                    color: selected == Gender.name ?  enabled : bgColor,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child:  TextField(
                    controller: _nomeText,
                    onTap: (){
                      setState(() {
                        selected = Gender.name;
                      });
                    },
                    decoration: InputDecoration(
                      enabledBorder: InputBorder.none,
                      border:InputBorder.none,
                      prefixIcon: Icon(Icons.person_pin_outlined,color: selected == Gender.name ? enabledtxt : deaible),
                      hintText: 'SEU NOME',
                      hintStyle: TextStyle(
                        color:  selected == Gender.name ? enabledtxt : deaible,
                      ),
                    ),
                    style:  TextStyle(color:  selected == Gender.name ? enabledtxt : deaible, fontWeight:FontWeight.bold),
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
                  height:he * 0.082,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: secondaryColor, width: 2),
                    color: selected == Gender.Email ?  enabled : bgColor,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child:  TextField(
                    controller: _emailText,
                    onTap: (){
                      setState(() {
                        selected = Gender.Email;
                      });
                    },
                    decoration: InputDecoration(
                      enabledBorder: InputBorder.none,
                      border:InputBorder.none,
                      prefixIcon: Icon(Icons.email_outlined,color: selected == Gender.Email ? enabledtxt : deaible),
                      hintText: 'E-MAIL',
                      hintStyle: TextStyle(
                        color:  selected == Gender.Email ? enabledtxt : deaible,
                      ),
                    ),
                    style:  TextStyle(color:  selected == Gender.Email ? enabledtxt : deaible, fontWeight:FontWeight.bold),
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
                  height:he * 0.082,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor, width: 2),
                      color: selected == Gender.password ? enabled : bgColor
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _passwordText,
                    onTap: (){
                      setState(() {
                        selected = Gender.password;
                      });
                    },
                    decoration: InputDecoration(
                        enabledBorder: InputBorder.none,
                        border:InputBorder.none,
                        prefixIcon: Icon(Icons.lock_open_outlined,color: selected == Gender.password ? enabledtxt : deaible,),
                        suffixIcon: IconButton(
                          icon: ispasswordev ?  Icon(Icons.visibility_off,color: selected == Gender.password ? enabledtxt : deaible,): Icon(Icons.visibility,color: selected == Gender.password ? enabledtxt : deaible,) ,
                          onPressed: () => setState(() => ispasswordev = !ispasswordev ),
                        ),
                        hintText: 'SENHA',
                        hintStyle: TextStyle(
                            color: selected == Gender.password ? enabledtxt : deaible
                        )
                    ),
                    obscureText: ispasswordev ,
                    style:  TextStyle(color: selected == Gender.password ? enabledtxt : deaible,fontWeight:FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(
                height: he * 0.06,
              ),
              FadeAnimationWidget(
                delay: 1,
                child: TextButton(
                    onPressed: () async {
                      try{
                          if(_passwordText.text.isNotEmpty && _emailText.text.isNotEmpty && _nomeText.text.isNotEmpty)
                          {
                            alertDisplayLoading.alertLoading(context);
                            await _createUserWithEmailAndPassword(_passwordText.text.trim(), _emailText.text.trim(), _nomeText.text);
                          }
                          else {
                            displayAlert.notificationError(context, "Erro!", "Por favor preencha todos os campos!");
                          }
                      }
                      catch(e){
                        alertDisplayLoading.closeLoading(context);
                        displayAlert.notificationError(context, "Erro!", "Problemas para registrar usuário!");
                      }
                    },
                    style:  TextButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 80),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)
                        )
                    ),
                    child: Text("REGISTRAR",style: GoogleFonts.heebo(
                      color: Colors.black,
                      letterSpacing: 0.5,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),)
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
            children:  [
              Text("Já tem uma conta? ",style: GoogleFonts.heebo(
                color:   Colors.grey,
                letterSpacing: 0.5,
              )),
              GestureDetector(
                onTap: (){
                  Navigator.of(context).push(MaterialPageRoute(builder: (context){
                    return LoginView();
                  }
                  ));
                },
                child: Text("Entre",style: GoogleFonts.heebo(
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
