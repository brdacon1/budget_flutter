import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as globalUIDUser;
import '../Objetos/DADOS.dart';
import '../Objetos/ItensListBudget.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import '../Objetos/ObjectListItens.dart';
import '../Objetos/ObjectListObservationPDF.dart';
import '../Objetos/ObjectPagamentosCliente.dart';
import '../Objetos/ObjectRecived.dart';
import '../Objetos/ObjetoUIDUser.dart';
import '../Objetos/Owner.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;

class Db{

  Future<List<ItensListBudget>> getListItensGerador() async {
    List<ItensListBudget> yourModels = [];
    try
    {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/ITENS")
          .orderBy('CATEGORIA', descending: false)
          .get();

      List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      for (var document in documents) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        ItensListBudget item = ItensListBudget.fromMap(data);

        yourModels.add(item);
      }

    }
    catch (e)
    {
      print(e);
    }
    return yourModels;
  }

  Future<void> updatePDF(Owner orcamento) async {
    try {
      final CollectionReference infoPdfRef = FirebaseFirestore.instance
          .collection('EMPRESAS/${UID.USER}/USERS/${UID.USER}/INFOPDF');
      final DocumentReference informationDocRef = infoPdfRef.doc('INFORMATION');

      await informationDocRef.update(orcamento.toJson());

      print('PDF atualizado com sucesso!');
    } catch (e) {
      print('Erro ao atualizar o PDF: $e');
    }
  }

  Future<List<ObjectListObservationPDF>> getListComment(String? ID) async {
    try {
      var group = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${ID}/OBSERVACAO")
          .get();

      List<ObjectListObservationPDF> yourModels = group.docs.map((doc) => ObjectListObservationPDF.fromSnapshot(doc)).toList();
      return yourModels;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<List<ObjectListItens>> getListItemsGenerator(String? ID) async {
    List<ObjectListItens> yourModels = [];
    try
    {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${ID}/ITENS")
          .orderBy('CATEGORIA', descending: false)
          .get();

      yourModels = querySnapshot.docs.map<ObjectListItens>((doc) {
        final objectListItens = ObjectListItens.fromMap(doc.data()!);
        objectListItens.id = doc.id;
        objectListItens.checkBox = false;
        objectListItens.selectProduct = false;
        return objectListItens;
      }).toList();
    }
    catch (e)
    {

    }
    return yourModels;
  }

  Future<void> savePDF(Owner pdfInfo) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/INFOPDF")
        .doc("INFORMATION")
        .set({
            'EMPRESA': pdfInfo.empresa,
            'EMAIL': pdfInfo.email,
            'CNPJ': pdfInfo.cnpj,
            'RUA': pdfInfo.rua,
            'BAIRRO': pdfInfo.bairro,
            'CITY': pdfInfo.city,
            'CEP': pdfInfo.cep,
            'FOTOID': pdfInfo.fotoId,
            'FONE': pdfInfo.fone,
            'LOGONAME': pdfInfo.logoName,
        });
  }

  Future<void> saveUserAdm(ObjetoUIDUser userInfo) async {
    await FirebaseFirestore.instance
        .collection("USUARIOS/")
        .doc(userInfo.USER)
        .set({'USER' : userInfo.USER,
              'FONE' : userInfo.FONE,
              'EMAIL' : userInfo.EMAIL,
              'NOME' : userInfo.NOME,
              'Id': userInfo.Id,
              'AutoRenewing' : userInfo.AutoRenewing,
              'IdPay' : userInfo.IdPay,
              'ProductId' : userInfo.ProductId,
              'PurchaseToken' : userInfo.PurchaseToken,
        });
  }

  Future <void> updateItemsDADOS() async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .doc(Orcamento.ID)
        .update({
      'ID': Orcamento.ID,
      'DATA' : Orcamento.DATA,
      'RUA' : Orcamento.RUA,
      'GERADO' : Orcamento.GERADO,
      'BAIRRO' : Orcamento.BAIRRO,
      'CITY' : Orcamento.CITY,
      'EMAIL' : Orcamento.EMAIL,
      'ENDERECO' : Orcamento.ENDERECO,
      'FONE' : Orcamento.FONE,
      'NOMECLIENTE' : Orcamento.NOMECLIENTE,
      'NOMEEMPRESA' : Orcamento.NOMEEMPRESA,
      'STATUS' : Orcamento.STATUS,
      'CEP' : Orcamento.CEP,
      'VALORTOTAL' : Orcamento.VALORTOTAL}).then((value) async {
    }).then((value) {
      Orcamento.IDORCAMENTO = Orcamento.ID;
      Orcamento.VALORTOTAL = Orcamento.VALORTOTAL ?? 0;
    });
  }

  Future<void> updateUserAdm(ObjetoUIDUser userInfo) async {
    await FirebaseFirestore.instance
        .collection("USUARIOS/")
        .doc(userInfo.USER)
        .update({'USER' : userInfo.USER,
      'FONE' : userInfo.FONE,
      'EMAIL' : userInfo.EMAIL,
      'NOME' : userInfo.NOME,
      'Id': userInfo.Id,
      'AutoRenewing' : userInfo.AutoRenewing,
      'IdPay' : userInfo.IdPay,
      'ProductId' : userInfo.ProductId,
      'PurchaseToken' : userInfo.PurchaseToken,
    });
  }

  Future<void> saveItemsList(List<ObjectListItens> addItems) async {
    for(int i = 0; i < addItems.length; i++)
    {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/ITENS")
          .doc(addItems[i].id)
          .set({'CATEGORIA': addItems[i].CATEGORIA,
          'DESCRICAO' : addItems[i].DESCRICAO,
          'PRECO' : addItems[i].PRECO,
          'QTD' : addItems[i].QTD,
          'MEDIDA' : addItems[i].MEDIDA,
          'TOTAL' : addItems[i].TOTAL,
          'IDPRODUCT': addItems[i].id,})
          .then((value) async {});
    }
  }
  Future<void> addComment(List<ObjectListObservationPDF> addComments) async {
    try
    {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      for(int i = 0; i < addComments.length; i++)
      {
         await FirebaseFirestore.instance
               .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/OBSERVACAO")
               .doc()
               .set({'OBSERVACAO': addComments[i].observacao, 'DATA': formatted
         });
      }
    }
    catch (e){}
  }

  Future <void> saveBudget(DADOS orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .doc(orcamento.ID)
        .set({
      'ID': orcamento.ID,
      'DATA' : orcamento.DATA,
      'RUA' : orcamento.RUA,
      'GERADO' : orcamento.GERADO,
      'BAIRRO' : orcamento.BAIRRO,
      'CITY' : orcamento.CITY,
      'EMAIL' : orcamento.EMAIL,
      'ENDERECO' : orcamento.ENDERECO,
      'FONE' : orcamento.FONE,
      'NOMECLIENTE' : orcamento.NOMECLIENTE,
      'NOMEEMPRESA' : orcamento.NOMEEMPRESA,
      'STATUS' : orcamento.STATUS,
      'CEP' : orcamento.CEP,
      'VALORTOTAL' : orcamento.VALORTOTAL}).then((value) async {
    }).then((value) {
      Orcamento.IDORCAMENTO = orcamento.ID;
    });
  }

  Future<DADOS> getInformationOrcamento1() async {
    try {
      String collectionPath =
          "EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS";
      var document = await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(Orcamento.IDORCAMENTO)
          .get();
      var data = document.data();
      if (data != null) {
        var yourModel = DADOS.fromMap(data);
        return yourModel;
      } else {
        throw Exception("Document data is null");
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }
  Future<void> savePaymentCustomer(ObjectPagamentosCliente payment) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS/${Orcamento.IDRECIBO}/PAGAMENTOS")
        .add(payment.toMap());
  }

  Future<void> updatePaymentCustomer(ObjectPagamentosCliente orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS/${Orcamento.IDRECIBO}/PAGAMENTOS")
        .doc(orcamento.id)
        .update(orcamento.toMap()); // Certifique-se que sua classe ObjectPagamentosCliente tenha um método toMap() que converte o objeto para um Map.
  }


  Future<List<ObjectPagamentosCliente>> getListPayment(Recived recived, DADOS dados) async {
    double totalProducts = 0;
    var group = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS/${recived.ID}/PAGAMENTOS")
        .get();

    var yourModels = group.docs.map<ObjectPagamentosCliente>((doc) {
      final objectListItens = ObjectPagamentosCliente.fromMap(doc.data()!);
      objectListItens.id = doc.id;
      return objectListItens;
    }).toList();

    for (int index = 0; index < yourModels.length; index++) {
      totalProducts += yourModels[index].PRECO!;
    }
    if(recived.VALORTOTAL != totalProducts)
    {
      recived.VALORTOTAL = totalProducts;
      await savedRecived(recived);
    }

    return yourModels;
  }

  Future<bool> createUserWithGoogle(User? value, BuildContext context) async {
    try{
      final DADOS = ObjetoUIDUser();
      final PDF = Owner();
      DADOS.EMAIL = value!.email;
      DADOS.FONE = value!.phoneNumber;
      DADOS.USER = value!.uid;
      DADOS.NOME = value!.displayName;
      DADOS.Id = value!.uid;
      PDF.email = value!.email;
      PDF.empresa = "Minha Empresa";
      PDF.fone = '(15) 99111-1111';
      PDF.cep = '18016-456';
      PDF.city = 'Sorocaba - SP';
      PDF.rua = 'Ananias Pires do Amaral';
      PDF.bairro = 'Jardm Gonçalves';
      PDF.cnpj = '77.574.778/0001-39';
      PDF.logoName = '';
      PDF.fotoId = '';
      await saveUserAdm(DADOS);
      globalUIDUser.USER = value!.uid;
      globalUIDUser.NOME = value!.displayName;
      globalUIDUser.EMAIL = DADOS.EMAIL;
      globalUIDUser.FONE = DADOS.FONE;
      globalUIDUser.Id = DADOS.Id;
      globalUIDUser.IdPay = "";
      globalUIDUser.ProductId = "";
      globalUIDUser.PurchaseToken = "";
      globalUIDUser.AutoRenewing = false;
      await savePDF(PDF);
      return true;
    } catch (e){
      return false;
    }
  }

  Future<int> getNumberItems() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER.toString()}/USERS/${UID.USER.toString()}/PRICELIST")
        .get();

    final list = querySnapshot.docs.map<ObjectListItens>((doc) {
      final objectListItems = ObjectListItens.fromMap(doc.data()!);
      objectListItems.id = doc.id;
      objectListItems.checkBox = false;
      objectListItems.selectProduct = false;
      return objectListItems;
    }).toList();

    return list.length;
  }

  Future <bool> salvaItensList(ObjectListItens addItens) async {
    bool result = false;
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/ITENS")
        .doc(addItens.id)
        .set({'CATEGORIA': addItens.CATEGORIA,
      'DESCRICAO' : addItens.DESCRICAO,
      'PRECO' : addItens.PRECO,
      'QTD' : addItens.QTD,
      'MEDIDA' : addItens.MEDIDA,
      'TOTAL' : addItens.TOTAL,
      'IDPRODUCT': addItens.id,}).then((value) async {
       });
       return result;
  }

  Future<List<Recived>> getListRecived() async {
    var group = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS")
        .get();

   var yourModels = group.docs.map<Recived>((doc) {
      final objectListItens = Recived.fromMap(doc.data()!);
      objectListItens.ID = doc.id;
      objectListItens.checkBox = false;
      return objectListItens;
    }).toList();

    return yourModels;
  }

  Future<void> savedRecived(Recived recived) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS")
        .doc(recived.ID)
        .set(recived.toMap());
  }

  Future<void> deleteRecived(Recived recived) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS")
        .doc(recived.ID)
        .delete();
  }

  Future<void> deletePaymentCustomer(String id) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/RECIBOS/${Orcamento.IDRECIBO}/PAGAMENTOS")
        .doc(id)
        .delete();
  }

  Future<Owner> getInformationEnterprise() async {
    try {
      var document = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/INFOPDF")
          .doc("INFORMATION")
          .get();

      var yourModel = Owner.fromJson(document.data());
      return yourModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> authGoogle() async {
    String uid = "";
    try
    {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await _auth.signInWithCredential(credential).then((userCredential) async => {
        uid = userCredential.credential!.accessToken!,
      });
      return uid;
    } catch(e){
      return "NOT_AUTH";
    }
  }

  Future<List<ObjectListObservationPDF>> getListComentarioPDF() async {
    try {
      var group = await FirebaseFirestore.instance
          .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS/${Orcamento.IDORCAMENTO}/OBSERVACAO")
          .get();

      List<ObjectListObservationPDF> yourModels = group.docs.map((doc) => ObjectListObservationPDF.fromSnapshot(doc)).toList();
      return yourModels;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

}