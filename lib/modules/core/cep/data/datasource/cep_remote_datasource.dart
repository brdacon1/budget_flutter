import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oflite/modules/core/cep/data/model/address.dart';

/// Fonte remota de dados de CEP (ViaCEP).
class CepRemoteDataSource {
  /// Consulta o CEP e retorna o [Address] bruto (JSON parseado).
  Future<Address> getAddress(String cep) async {
    final endereco = Address();
    final url = 'https://viacep.com.br/ws/$cep/json';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final tagObjsJson = jsonDecode(response.body.toLowerCase());
      endereco.cep = tagObjsJson['cep'];
      endereco.bairro = tagObjsJson['bairro'];
      endereco.complemento = tagObjsJson['complemento'];
      endereco.gia = tagObjsJson['gia'];
      endereco.ibge = tagObjsJson['ibge'];
      endereco.localidade = tagObjsJson['localidade'];
      endereco.logradouro = tagObjsJson['logradouro'];
      endereco.uf = tagObjsJson['uf'];
      endereco.unidade = tagObjsJson['unidade'];
    }

    return endereco;
  }
}
