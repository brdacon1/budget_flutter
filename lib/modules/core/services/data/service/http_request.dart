import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as uid;
import 'package:oflite/shared/models/global_uid_budget.dart' as budget;
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/shared/models/items_list_budget.dart';
import 'package:oflite/shared/models/payment_customer.dart';
import 'package:oflite/shared/models/receipt.dart';
import 'package:oflite/shared/models/items_budget.dart';
import 'package:oflite/shared/models/observation_pdf.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'loading_event.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;

class HttpRequest{
  final alertDisplayLoading = LoadingEvent();

  Future<List<ItemsBudget>> getListItensGerador() async {
    List<ItemsBudget> yourModels = [];
    try
    {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS")
          .orderBy('CATEGORIA', descending: false)
          .get();

      List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      for (var document in documents) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        ItemsBudget item = ItemsBudget.fromMap(data);

        yourModels.add(item);
      }

    }
    catch (e)
    {
      print(e);
    }
    return yourModels;
  }

  Future<void> updatePDF(OwnerPdf orcamento) async {
    try {
      final CollectionReference infoPdfRef = FirebaseFirestore.instance
          .collection('EMPRESAS/${uid.user}/USERS/${uid.user}/INFOPDF');
      final DocumentReference informationDocRef = infoPdfRef.doc('INFORMATION');

      await informationDocRef.update(orcamento.toJson());

      print('PDF atualizado com sucesso!');
    } catch (e) {
      print('Erro ao atualizar o PDF: $e');
    }
  }
  Future<void> updateUserAdm(InfoUser userInfo) async {
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
  Future<List<ObservationPdf>> getListComment(String? ID) async {
    try {
      var group = await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${ID}/OBSERVACAO")
          .get();

      List<ObservationPdf> yourModels = group.docs.map((doc) => ObservationPdf.fromSnapshot(doc)).toList();
      return yourModels;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<List<ItemsListBudget>> getListItemsGenerator(String? ID) async {
    List<ItemsListBudget> yourModels = [];
    try
    {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${ID}/ITENS")
          .orderBy('CATEGORIA', descending: false)
          .get();

      yourModels = querySnapshot.docs.map<ItemsListBudget>((doc) {
        final objectListItens = ItemsListBudget.fromMap(doc.data()!);
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

  Future<void> savePDF(OwnerPdf pdfInfo) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/INFOPDF")
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

  Future<void> saveUserAdm(InfoUser userInfo) async {
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
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS")
        .doc(budget.ID)
        .update({
      'ID': budget.ID,
      'DATA' : budget.DATA,
      'RUA' : budget.RUA,
      'GERADO' : budget.GERADO,
      'BAIRRO' : budget.BAIRRO,
      'CITY' : budget.CITY,
      'EMAIL' : budget.EMAIL,
      'ENDERECO' : budget.ENDERECO,
      'FONE' : budget.FONE,
      'NOMECLIENTE' : budget.NOMECLIENTE,
      'NOMEEMPRESA' : budget.NOMEEMPRESA,
      'STATUS' : budget.STATUS,
      'CEP' : budget.CEP,
      'VALORTOTAL' : budget.VALORTOTAL}).then((value) async {
    }).then((value) {
      budget.IDORCAMENTO = budget.ID;
      budget.VALORTOTAL = budget.VALORTOTAL ?? 0;
    });
  }

  Future<void> saveItemsList(List<ItemsListBudget> addItems) async {
    for(int i = 0; i < addItems.length; i++)
    {
      await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS")
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
  Future<void> addComment(List<ObservationPdf> addComments) async {
    try
    {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String formatted = formatter.format(now);

      for(int i = 0; i < addComments.length; i++)
      {
         await FirebaseFirestore.instance
               .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/OBSERVACAO")
               .doc()
               .set({'OBSERVACAO': addComments[i].observacao, 'DATA': formatted
         });
      }
    }
    catch (e){}
  }

  Future <void> saveBudget(CustomerInfo orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS")
        .doc(orcamento.id)
        .set({
      'ID': orcamento.id,
      'DATA' : orcamento.data,
      'RUA' : orcamento.street,
      'GERADO' : orcamento.generated,
      'BAIRRO' : orcamento.neighborhood,
      'CITY' : orcamento.city,
      'EMAIL' : orcamento.email,
      'ENDERECO' : orcamento.address,
      'FONE' : orcamento.phone,
      'NOMECLIENTE' : orcamento.customerName,
      'NOMEEMPRESA' : orcamento.companyName,
      'STATUS' : orcamento.status,
      'CEP' : orcamento.zip,
      'VALORTOTAL' : orcamento.totalValue}).then((value) async {
    }).then((value) {
      budget.IDORCAMENTO = orcamento.id;
    });
  }

  Future<CustomerInfo> getInformationOrcamento1() async {
    try {
      String collectionPath =
          "EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS";
      var document = await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(budget.IDORCAMENTO)
          .get();
      var data = document.data();
      if (data != null) {
        var yourModel = CustomerInfo.fromMap(data);
        return yourModel;
      } else {
        throw Exception("Document data is null");
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<void> savePaymentCustomer(PaymentCustomer payment) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS/${budget.IDRECIBO}/PAGAMENTOS")
        .add(payment.toMap());
  }

  Future<void> updatePaymentCustomer(PaymentCustomer orcamento) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS/${budget.IDRECIBO}/PAGAMENTOS")
        .doc(orcamento.id)
        .update(orcamento.toMap());
  }


  Future<List<PaymentCustomer>> getListPayment(Receipt recived, CustomerInfo dados) async {
    // Se o recibo ainda não foi persistido (id vazio) ou o orçamento não foi
    // definido, não há pagamentos a carregar — evita caminho com "//" no
    // Firestore ("A collection path must not contain '//'"), que ocorria ao
    // abrir a aba de Pagamentos antes de salvar um recibo recém-criado.
    if (recived.id == null || recived.id!.isEmpty ||
        budget.IDORCAMENTO == null || budget.IDORCAMENTO!.isEmpty) {
      return <PaymentCustomer>[];
    }
    double totalProducts = 0;
    var group = await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS/${recived.id}/PAGAMENTOS")
        .get();

    var yourModels = group.docs.map<PaymentCustomer>((doc) {
      final objectListItens = PaymentCustomer.fromMap(doc.data());
      objectListItens.id = doc.id;
      return objectListItens;
    }).toList();

    for (int index = 0; index < yourModels.length; index++) {
      totalProducts += yourModels[index].PRECO!;
    }
    if(recived.valorTotal != totalProducts)
    {
      await savedRecived(recived.copyWith(valorTotal: totalProducts));
    }

    return yourModels;
  }

  Future<void> createUserWithGoogle(User? value, BuildContext? context) async {
    try{
      if (context != null) {
        alertDisplayLoading.alertLoading(context);
      }
      final DADOS = InfoUser();
      final PDF = OwnerPdf();
      DADOS.EMAIL = value?.email ?? '';
      DADOS.FONE = value?.phoneNumber ?? '';
      DADOS.USER = value?.uid ?? '';
      DADOS.NOME = value?.displayName ?? '';
      DADOS.Id = value?.uid ?? '';
      PDF.email = value?.email ?? '';
      PDF.empresa = "Minha Empresa";
      PDF.logoName = '';
      PDF.fotoId = '';
      await saveUserAdm(DADOS);
      uid.user = value?.uid ?? '';
      uid.name = value?.displayName ?? '';
      uid.email = DADOS.EMAIL;
      uid.phone = DADOS.FONE;
      uid.id = DADOS.Id;
      uid.idPay = "";
      uid.productId = "";
      uid.purchaseToken = "";
      uid.autoRenewing = false;
      await savePDF(PDF).then((_) {
        if (context != null) {
          alertDisplayLoading.closeLoading(context);
        }
      });
    } catch (e){
      if (context != null) {
        alertDisplayLoading.closeLoading(context);
      }
    }
  }
 Future<int> getNumberItems() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user.toString()}/USERS/${uid.user.toString()}/PRICELIST")
        .get();

    final list = querySnapshot.docs.map<ItemsListBudget>((doc) {
      final objectListItems = ItemsListBudget.fromMap(doc.data());
      objectListItems.id = doc.id;
      objectListItems.checkBox = false;
      objectListItems.selectProduct = false;
      return objectListItems;
    }).toList();

    return list.length;
  }

  Future <bool> salvaItensList(ItemsListBudget addItens) async {
    bool result = false;
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/ITENS")
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

  Future<List<Receipt>> getListRecived() async {
    var group = await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS")
        .get();

   var yourModels = group.docs.map<Receipt>((doc) {
      return Receipt.fromJson(doc.data())
          .copyWith(id: doc.id, checkBox: false);
    }).toList();

    return yourModels;
  }

  Future<void> savedRecived(Receipt recived) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS")
        .doc(recived.id)
        .set(recived.toJson());
  }

  Future<void> deleteRecived(Receipt recived) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS")
        .doc(recived.id)
        .delete();
  }

  Future<void> deletePaymentCustomer(String id) async {
    await FirebaseFirestore.instance
        .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/RECIBOS/${budget.IDRECIBO}/PAGAMENTOS")
        .doc(id)
        .delete();
  }

  Future<OwnerPdf> getInformationEnterprise() async {
    try {
      var document = await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/INFOPDF")
          .doc("INFORMATION")
          .get();

      var yourModel = OwnerPdf.fromJson(document.data());
      return yourModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> authGoogle() async {
    // O login com o Google já foi feito na tela de login e a sessão do
    // Firebase permanece persistida entre execuções do app. Por isso,
    // basta reutilizar o usuário atual para obter um idToken válido,
    // **sem** disparar novamente o fluxo interativo do Google SignIn
    // (que abre o seletor de contas em toda requisição de imagem/arquivo).
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return "NOT_AUTH";
      }
      final idToken = await currentUser.getIdToken();
      return idToken ?? "";
    } catch (e) {
      return "NOT_AUTH";
    }
  }

  Future<List<ObservationPdf>> getListComentarioPDF() async {
    try {
      var group = await FirebaseFirestore.instance
          .collection("EMPRESAS/${uid.user}/USERS/${uid.user}/ORCAMENTOS/${budget.IDORCAMENTO}/OBSERVACAO")
          .get();

      List<ObservationPdf> yourModels = group.docs.map((doc) => ObservationPdf.fromSnapshot(doc)).toList();
      return yourModels;
    } catch (e) {
      rethrow;
    }
  }

}