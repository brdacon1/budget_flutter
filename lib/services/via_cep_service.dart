import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oflite/models/address.dart';

class ViaCepService {

  Address endereco = Address();

  Future <Address> getAdress(String CEP) async{
      String adress = 'https://viacep.com.br/ws/'+ CEP +'/json';
      Map<String, String> requestHeaders = {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      await http.get(Uri.parse(adress),
          headers: requestHeaders).then((value) async {
           var arrayObjsText = value.body.toLowerCase();
           var tagObjsJson = jsonDecode(arrayObjsText);
           endereco.cep = tagObjsJson['cep'];
           endereco.bairro = tagObjsJson['bairro'];
           endereco.complemento = tagObjsJson['complemento'];
           endereco.gia = tagObjsJson['gia'];
           endereco.ibge = tagObjsJson['ibge'];
           endereco.localidade = tagObjsJson['localidade'];
           endereco.logradouro = tagObjsJson['logradouro'];
           endereco.uf = tagObjsJson['uf'];
           endereco.unidade = tagObjsJson['unidade'];
        });
        return endereco;
  }

}