import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Fonte externa para o Firebase Crashlytics.
///
/// Não conhece entidades de negócio; expõe apenas o acesso bruto ao SDK.
class CrashlyticsRemoteDataSource {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsRemoteDataSource({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) =>
      _crashlytics.recordFlutterFatalError(details);

  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, fatal: fatal);

  Future<void> setUserIdentifier(String id) =>
      _crashlytics.setUserIdentifier(id);
}
