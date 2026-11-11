import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:oflite/modules/core/cep/data/model/address.dart';
import 'package:oflite/shared/utils/interceptor/dio_client.dart';

/// Fonte remota de dados de CEP (ViaCEP).
class CepRemoteDataSource {
  final DioClient _dioClient = DioClient();

  /// Consulta o CEP e retorna o [Address] bruto (JSON parseado).
  Future<Address> getAddress(String cep) async {
    final endereco = Address();
    final url = 'https://viacep.com.br/ws/$cep/json';
    final response = await _dioClient.dioClient.get(
      url,
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      final tagObjsJson = jsonDecode(jsonEncode(response.data).toLowerCase());
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
