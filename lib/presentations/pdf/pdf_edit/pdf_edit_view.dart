import 'dart:typed_data';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/presentations/image/image_edit_view.dart';
import 'package:oflite/presentations/subscription/subscription_view.dart';
import 'package:oflite/Services/http_request.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oflite/services/via_cep_service.dart' as CEP;
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/models/global_uid_user.dart' as globalUIDUser;
import 'package:oflite/models/owner_pdf.dart';
import '../../../Services/display_alert.dart';
import '../../../Services/loading_event.dart';
import '../../../common/widgets/anmition/fade_animation_widget.dart';
import '../../../common/constants/constants.dart';
import 'package:http/http.dart' as http;

FirebaseFirestore firestore = FirebaseFirestore.instance;

enum Gender{
  fullname,
  email,
  phone,
  site,
  cpf,
  cep,
  rua,
  data,
  city,
  bairro,
}

TextEditingController _nameText = TextEditingController();
TextEditingController _phoneText = TextEditingController();
TextEditingController _emailText = TextEditingController();
TextEditingController _cpfText = TextEditingController();
TextEditingController _cepText = TextEditingController();
TextEditingController _ruaText = TextEditingController();
TextEditingController _cityText = TextEditingController();
TextEditingController _bairroText = TextEditingController();


class PdfEditView extends StatefulWidget {
  const PdfEditView({Key? key}) : super(key: key);


  @override
  State<PdfEditView> createState() => _PdfEditView();
}

class _PdfEditView extends State<PdfEditView> {
  OwnerPdf owner = OwnerPdf();
  var db = HttpRequest();
  Color enabledtxt = Colors.white;
  Color deaible = Colors.white;
  Gender? selected;
  String? nameButton;
  final alertDisplayLoading = LoadingEvent();
  final GlobalKey<ExpansionTileCardState> cardA = GlobalKey();
  late Future<Uint8List?> fileContentFuture;
  var displayAlert = DisplayAlert();

  var maskFormatter =  MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskFormatterCNPJ =  MaskTextInputFormatter(
      mask: '##.###.###/0001-##',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskCep =  MaskTextInputFormatter(
      mask: '#####-###',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );
  var maskDate =  MaskTextInputFormatter(
      mask: '',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  Future<Uint8List?> initialData() async {
    try {
      String? token = '';

      owner = await db.getInformationEnterprise();

      if(UID.googleAuth!) {
        token = await db.authGoogle();
      }
      else{
        var auth = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: globalUIDUser.email!.trim(),
          password: globalUIDUser.password!.trim(),
        );
        token = await auth.user?.getIdToken();
      }

      var endpointUrl =
          'https://firebasestorage.googleapis.com/v0/b/orcamentofacil-lite.appspot.com/o/${owner.logoName}?alt=media&token=${owner.fotoId}';
      var response = await http.get(
        Uri.parse(endpointUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json;odata=verbose',
        },
      );

      _nameText.text = owner.empresa!;
      _phoneText.text = owner.fone!;
      _emailText.text = owner.email!;
      _cpfText.text = owner.cnpj!;
      _cepText.text = owner.cep!;
      _ruaText.text = owner.rua!;
      _cityText.text = owner.city!;
      _bairroText.text = owner.bairro!;
      setState(() {});

      // Verificar se a resposta é válida e contém a imagem
      if (response.statusCode == 200) {
        // Verify if the response contains valid image data
        if (response.headers["content-type"]?.startsWith("image/") == true) {
          // Se a resposta for válida e contém a imagem, retornar os bytes da imagem
          return response.bodyBytes;
        } else {
          // Se a resposta não contém uma imagem válida, retornar null
          return null;
        }
      } else {
        // Se a resposta não contém a imagem, retornar null
        return null;
      }
    } catch (e) {
      // Se ocorrer algum erro na requisição, retornar null
      return null;
    }
  }

  Widget _image(Uint8List? fileContent) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (fileContent != null && fileContent.isNotEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: Image.memory(
          fileContent,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: const Icon(Icons.image, size: 100),
      );
    }
  }

  Widget _imageCard(Uint8List? fileContent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              color: Colors.white,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: _image(fileContent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  initState() {
    super.initState();
    fileContentFuture = initialData();
  }

  // Function to update the fileContentFuture
  void _updateFileContentFuture() {
    setState(() {
      fileContentFuture = initialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    var we = MediaQuery.of(context).size.width;
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            SizedBox(
              height: he * 0.07,
            ),
            GestureDetector(
              onTap: (){
                Navigator.pop(context, true);
              },
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.040),
                child: const Icon(Icons.arrow_back_outlined,color: Colors.white,size: 35.0,),
              ),
            ),
            SizedBox(
              height: he * 0.03,
            ),
            FadeAnimationWidget(
              delay: 1,
              child: Container(
                alignment: Alignment.topLeft,
                margin: EdgeInsets.only(left: we * 0.05),
                child: Text('Editar PDF',style: GoogleFonts.heebo(
                    color: whiteColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    letterSpacing: 2
                ),
                ),
              ),
            ),
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(left: we * 0.05),
              child: Text("Informações do PDF",style: GoogleFonts.heebo(
                  color: Colors.grey,
                  letterSpacing: 1),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: he * 0.02,
                        ),
                    FutureBuilder<Uint8List?>(
                      future: fileContentFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text('Erro ao carregar a imagem'),
                          );
                        } else {
                          if (UID.autoRenewing!) {
                            if (snapshot.data != null) {
                              return GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageEditView(
                                        owner: owner,
                                        title: 'Editar Logo',
                                      ),
                                    ),
                                  ).then((value) {
                                    // Atualizar o FutureBuilder quando voltar da tela de edição
                                    _updateFileContentFuture();
                                  });
                                },
                                child: _imageCard(snapshot.data!),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageEditView(
                                          owner: owner,
                                          title: 'Editar Logo',
                                        ),
                                      ),
                                    ).then((value) {
                                      // Atualizar o FutureBuilder quando voltar da tela de edição
                                      _updateFileContentFuture();
                                    });
                                  },
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Sem imagem disponível',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(color: Colors.white),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          'Toque para incluir nova imagem',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (snapshot.data != null) {
                              return GestureDetector(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubscriptionView(),
                                    ),
                                  );
                                },
                                child: _imageCard(snapshot.data!),
                              );
                            } else {
                              // Display a fallback image from resources when Firebase image is null
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SubscriptionView(),
                                      ),
                                    );
                                  },
                                  child: Align(
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sem imagem disponível',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(color: Colors.white),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Toque para incluir nova imagem',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                 ),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                              child: ExpansionTileCard(
                                initiallyExpanded: true,
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                              leading: const CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(Icons.account_balance, color: Colors.white,)),
                              title: Text("Informações da empresa",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1
                                ),
                              ),
                              subtitle: Text("Clique para editar",style: GoogleFonts.heebo(
                                  color: whiteColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                  letterSpacing: 1
                               ),
                              ),
                              children:  <Widget>[
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height: he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.fullname ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      readOnly: false,
                                      controller: _nameText,
                                      onTap: () async {

                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.account_balance,color: selected == Gender.fullname ? enabledtxt : deaible),
                                        hintText: 'Nome da empresa',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.fullname ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.phone ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [maskFormatter],
                                      controller: _phoneText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.phone;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.phone_android_outlined, color: selected == Gender.phone ? enabledtxt : deaible),
                                        hintText: 'Telefone',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.phone ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.email ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _emailText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.email;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.email_outlined, color: selected == Gender.email ? enabledtxt : deaible),
                                        hintText: 'E-mail',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.email ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.phone ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [maskFormatterCNPJ],
                                      controller: _cpfText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.cpf;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.contact_page_outlined, color: selected == Gender.cpf ? enabledtxt : deaible),
                                        hintText: 'CNPJ',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.cpf ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                            child: Theme(
                              data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
                              child: ExpansionTileCard(
                                expandedTextColor: whiteColor,
                                baseColor: secondaryColor,
                                expandedColor: secondaryColor,
                              leading: const CircleAvatar(
                                  backgroundColor: bgColor,
                                  child: Icon(Icons.location_on_outlined, color: whiteColor,)),
                              title: Text("Informações de endereço",style: GoogleFonts.heebo(
                                    color: whiteColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1
                                ),
                              ),
                              subtitle: Text("Clique para editar",style: GoogleFonts.heebo(
                                  color: whiteColor,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                  letterSpacing: 1
                               ),
                              ),
                              children:  <Widget>[
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.cep ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) async {
                                        var findAdress = CEP.ViaCepService();
                                        if(value.length == 9)
                                        {
                                          var adress =  await findAdress.getAdress(value);
                                          setState(() {
                                            _ruaText.text = adress.logradouro!.toUpperCase();
                                            _cityText.text = adress.localidade!.toUpperCase();
                                            _bairroText.text = adress.bairro!.toUpperCase();
                                          });
                                        }
                                      },
                                      inputFormatters: [maskCep],
                                      controller: _cepText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.cep;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.add_location_outlined, color: selected == Gender.cep ? enabledtxt : deaible),
                                        hintText: 'CEP',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.cep ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.rua ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _ruaText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.rua;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_on_outlined, color: selected == Gender.rua ? enabledtxt : deaible),
                                        hintText: 'Rua',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.rua ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.city ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _cityText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.city;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_city_outlined, color: selected == Gender.city ? enabledtxt : deaible),
                                        hintText: 'Cidade',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.city ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                                FadeAnimationWidget(
                                  delay: 1,
                                  child: Container(
                                    width: we * 0.8,
                                    height:he * 0.071,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: selected == Gender.bairro ?  bgColor : bgColor,
                                    ),
                                    padding: const EdgeInsets.all(8.0),
                                    child:  TextField(
                                      controller: _bairroText,
                                      onTap: (){
                                        setState(() {
                                          selected = Gender.bairro;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        enabledBorder: InputBorder.none,
                                        border:InputBorder.none,
                                        prefixIcon: Icon(Icons.location_searching, color: selected == Gender.bairro ? enabledtxt : deaible),
                                        hintText: 'Bairro',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                      ),
                                      style:  TextStyle(color:  selected == Gender.bairro ? enabledtxt : deaible, fontWeight:FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: he * 0.02,
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: he * 0.02,
                        ),
                        FadeAnimationWidget(
                          delay: 1,
                          child: TextButton(
                            onPressed: (){
                              alertDisplayLoading.alertLoading(context);
                              var db = HttpRequest();
                              var localOwner = OwnerPdf();
                              var displayAlert = DisplayAlert();
                              localOwner.bairro = _bairroText.text;
                              localOwner.fotoId = owner.fotoId;
                              localOwner.city = _cityText.text;
                              localOwner.rua = _ruaText.text;
                              localOwner.cep = _cepText.text;
                              localOwner.email = _emailText.text;
                              localOwner.fone = _phoneText.text;
                              localOwner.cnpj = _cpfText.text;
                              localOwner.empresa = _nameText.text;
                              localOwner.logoName = owner.logoName;
                              db.savePDF(localOwner).then((value) => {
                                 alertDisplayLoading.closeLoading(context),
                                 displayAlert.notification(context, "Feito!", "Dados do PDF atualizados com sucesso!"),
                              });
                            },
                            style: TextButton.styleFrom(
                                backgroundColor: buttonColor,
                                padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 70),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0)
                                )
                            ),
                            child: Text("Atualizar",style: GoogleFonts.heebo(
                              color: Colors.black,
                              letterSpacing: 0.5,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: he * 0.10,
                        ),
                      ]
                  ),
                ),
              ),
            ),
          ]
      ),
    );
  }
}
