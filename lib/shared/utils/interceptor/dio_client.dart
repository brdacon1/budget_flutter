import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton que centraliza as instâncias do [Dio] utilizadas pelo app.
///
/// Expor dois clientes distintos permite configurar comportamentos diferentes
/// para requisições genéricas (JSON) e para downloads autenticados (bytes).
class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  DioClient._internal() {
    _dioClient = _createJsonClient();
    _dioClientAuth = _createAuthClient();
  }

  late final Dio _dioClient;
  late final Dio _dioClientAuth;

  /// Cliente para requisições JSON genéricas (Firestore REST, ViaCEP, Cloud
  /// Functions etc.). O `responseType` padrão é [ResponseType.json], logo
  /// `response.data` já vem como `Map`/`List` decodificados.
  Dio get dioClient => _dioClient;

  /// Cliente para requisições que exigem autenticação ou download de bytes
  /// (imagens do Firebase Storage). O `responseType` padrão é
  /// [ResponseType.bytes], então `response.data` pode ser convertido para
  /// [Uint8List].
  ///
  /// Caso nenhum header `Authorization` seja informado na requisição, o
  /// interceptor tenta adicionar automaticamente o ID token do usuário logado
  /// no Firebase.
  Dio get dioClientAuth => _dioClientAuth;

  Dio _createJsonClient() {
    return Dio(
      BaseOptions(
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, dynamic>{
          'Accept': 'application/json',
        },
      ),
    )..interceptors.add(_logInterceptor);
  }

  Dio _createAuthClient() {
    final client = Dio(
      BaseOptions(
        responseType: ResponseType.bytes,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_hasAuthorizationHeader(options.headers)) {
            final token = await _currentFirebaseToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

    client.interceptors.add(_logInterceptor);

    return client;
  }

  Interceptor get _logInterceptor {
    return InterceptorsWrapper(
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[DioClient] ${error.requestOptions.method} '
              '${error.requestOptions.uri}: ${error.message}');
        }
        handler.next(error);
      },
    );
  }

  bool _hasAuthorizationHeader(Map<String, dynamic> headers) {
    return headers.keys.any(
      (key) => key.toLowerCase() == 'authorization',
    );
  }

  Future<String?> _currentFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
