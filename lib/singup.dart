import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/constants.dart';
import 'Models/Db.dart';
import 'Objetos/ObjetoUIDUser.dart';
import 'Objetos/Owner.dart';
import 'Services/display_alert.dart';
import 'Services/loading_event.dart';
import 'anmition/fadeanimation.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'login.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
TextEditingController _emailText = TextEditingController();
TextEditingController _passwordText = TextEditingController();

enum Gender{
  fullname,
  Email,
  password,
  confirmpassword,
  phone
}

class Singup extends StatefulWidget {
  const Singup({Key? key}) : super(key: key);

  @override
  _SingupState createState() => _SingupState();
}

class _SingupState extends State<Singup> {
  Color enabled = const Color(0xFF827F8A);
  Color enabledtxt = Colors.white;
  Color deaible = Colors.grey;
  bool ispasswordev = true;
  Gender? selected;
  final db = Db();
  final DADOS = ObjetoUIDUser();
  final PDF = Owner();
  final displayAlert = DisplayAlert();
  final alertDisplayLoading = LoadingEvent();

  Future<void> _createUserWithEmailAndPassword(String password, String email) async {

    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    ).then((value) async => {
        DADOS.EMAIL = email,
        DADOS.FONE = '15991111111',
        DADOS.USER = value.user!.uid,
        DADOS.NOME = 'Minha Empresa',
        DADOS.Id = value.user!.uid,
        PDF.email = email,
        PDF.empresa = "Minha Empresa",
        PDF.fone = '(15) 99111-1111',
        PDF.cep = '18016-456',
        PDF.city = 'Sorocaba - SP',
        PDF.rua = 'Ananias Pires do Amaral',
        PDF.bairro = 'Jardm Gonçalves',
        PDF.cnpj = '77.574.778/0001-39',
        PDF.logoName = '1_auto_pdf_oflite.png',
        PDF.fotoId = '09acd7c6-3133-40be-88c9-550698f6c4c1',
        await db.saveUserAdm(DADOS),
        UID.USER = value.user!.uid,
        UID.NOME = DADOS.NOME,
        UID.EMAIL = DADOS.EMAIL,
        UID.FONE = DADOS.FONE,
        UID.Id = DADOS.Id,
        UID.IdPay = "",
        UID.ProductId = "",
        UID.PurchaseToken = "",
        UID.AutoRenewing = false,
        await db.savePDF(PDF).then((value) => {
          alertDisplayLoading.closeLoading(context),
          Navigator.pushReplacementNamed(context, "/menu_tecnico"),
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
              FadeAnimation(
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
              FadeAnimation(
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
              SizedBox(
                height: he * 0.02,
              ),
              SizedBox(
                height: he * 0.02,
              ),
              FadeAnimation(
                delay: 1,
                child: Container(
                  width: we * 0.9,
                  height:he * 0.071,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
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
              FadeAnimation(
                delay: 1,
                child: Container(
                  width: we * 0.9,
                  height:he * 0.071,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
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
                height: he * 0.02,
              ),
              FadeAnimation(
                delay: 1,
                child: TextButton(
                    onPressed: () async {
                      try{
                        alertDisplayLoading.alertLoading(context);
                        await _createUserWithEmailAndPassword(_passwordText.text.trim(), _emailText.text.trim());
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
              SizedBox(
                  height: he * 0.13
              ),
              FadeAnimation(
                delay: 1,
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
                          return Login();
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
