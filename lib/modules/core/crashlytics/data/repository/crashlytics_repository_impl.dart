import 'package:flutter/foundation.dart';
import 'package:oflite/modules/core/crashlytics/data/datasource/crashlytics_remote_datasource.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';

/// Implementação do relatório de crashes.
///
/// Orquestra os handlers globais de erro; o acesso ao SDK fica no
/// [CrashlyticsRemoteDataSource].
class CrashlyticsRepositoryImpl implements CrashlyticsRepository {
  final CrashlyticsRemoteDataSource _dataSource;

  CrashlyticsRepositoryImpl(this._dataSource);

  @override
  Future<void> initialize() async {
    // Não polui o console do Firebase com crashes de desenvolvimento.
    await _dataSource.setCollectionEnabled(!kDebugMode);

    // Erros do framework Flutter (build, layout, paint).
    FlutterError.onError = _dataSource.recordFlutterFatalError;

    // Erros assíncronos fora do framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      _dataSource.recordError(error, stack, fatal: true);
      return true;
    };
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack) =>
      _dataSource.recordError(error, stack);

  @override
  Future<void> setUser(String? uid) => _dataSource.setUserIdentifier(uid ?? '');
}
