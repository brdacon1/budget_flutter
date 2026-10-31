import 'package:oflite/modules/core/cep/domain/repository/cep_repository.dart';
import 'package:oflite/modules/core/cep/data/datasource/cep_remote_datasource.dart';
import 'package:oflite/modules/core/cep/data/model/address.dart';

/// Implementação do repositório de CEP.
class CepRepositoryImpl implements CepRepository {
  final CepRemoteDataSource _dataSource;

  CepRepositoryImpl(this._dataSource);

  @override
  Future<Address> getAddress(String cep) => _dataSource.getAddress(cep);
}
