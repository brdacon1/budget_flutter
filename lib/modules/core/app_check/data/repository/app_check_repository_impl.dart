import 'package:flutter/foundation.dart' show debugPrint;
import 'package:oflite/modules/core/app_check/data/datasource/app_check_remote_datasource.dart';
import 'package:oflite/modules/core/app_check/domain/repository/app_check_repository.dart';

class AppCheckRepositoryImpl implements AppCheckRepository {
  final AppCheckRemoteDataSource _remote;

  AppCheckRepositoryImpl(this._remote);

  @override
  Future<void> initialize() async {
    try {
      await _remote.activate();
    } catch (e) {
      debugPrint('Erro ao ativar App Check: $e');
    }
  }
}
