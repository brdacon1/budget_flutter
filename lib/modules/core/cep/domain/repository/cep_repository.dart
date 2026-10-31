import 'package:oflite/modules/core/cep/data/model/address.dart';

/// Contrato para busca de endereço por CEP.
abstract class CepRepository {
  /// Consulta o endereço correspondente ao [cep].
  ///
  /// Retorna [Address] preenchido ou vazio em caso de falha.
  Future<Address> getAddress(String cep);
}
