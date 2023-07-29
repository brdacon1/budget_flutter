import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Objetos/DADOS.dart';
import '../Objetos/ItensListBudget.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;
import 'package:oflite/Objetos/globalUIDOrcamento.dart' as Orcamento;
import '../Objetos/ObjectListItens.dart';
import '../Objetos/ObjectListObservationPDF.dart';
import '../Objetos/ObjetoUIDUser.dart';
import '../Objetos/Owner.dart';

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