import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/items_budget.dart';
import 'package:oflite/models/observation_pdf.dart';

/// Camada de acesso aos dados do orçamento no fluxo **Web público**.
///
/// O aplicativo mobile lê/gravar o orçamento via `cloud_firestore`
/// autenticado como o próprio dono (`HttpRequest`). No fluxo Web, o cliente
/// **não** é o usuário autenticado — ele recebe apenas um *token provisório
/// do Firebase* (Firebase ID Token do dono, ~1h de validade) embutido na URL.
///
/// Para reutilizar as regras de negócio sem duplicar services e sem mexer no
/// `cloud_firestore` autenticado do mobile, este serviço lê/gravar o mesmo
/// caminho do Firestore (`EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{id}`) pela
/// **Firestore REST API**, enviando o token do dono em
/// `Authorization: Bearer {token}`. As regras de segurança do Firestore
/// continuam sendo a fonte de verdade: um token inválido/expirado é
/// rejeitado pela própria API (401/403).
///
/// Este serviço é **aditivo**: nada no app mobile depende dele.
class WebBudgetService {
  static const String _firestoreHost =
      'firestore.googleapis.com';

  /// Decodifica o payload de um JWT (Firebase ID Token) sem validar a
  /// assinatura — a validação real de acesso é feita pelo Firestore ao
  /// receber o token. Aqui só extraímos o `uid` do dono (necessário para
  /// montar o path) e checamos a expiração para UX.
  ///
  /// Retorna `null` se o token não for um JWT bem formado ou estiver expirado.
  static Map<String, dynamic>? decodeIdToken(String? token) {
    if (token == null || token.isEmpty) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = _decodeBase64Url(parts[1]);
      final Map<String, dynamic> claims = jsonDecode(payload);
      final exp = claims['exp'];
      if (exp is num) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (exp.toInt() < now) return null; // expirado
      } else {
        return null; // sem exp = não é um token provisório válido
      }
      // UID do dono vem em `user_id` (Firebase) ou `sub`.
      final uid = claims['user_id'] ?? claims['sub'];
      if (uid == null || (uid is String && uid.isEmpty)) return null;
      return claims;
    } catch (_) {
      return null;
    }
  }

  static String _decodeBase64Url(String src) {
    String output = src.replaceAll('-', '+').replaceAll('_', '');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw FormatException('Invalid base64url');
    }
    return utf8.decode(base64.decode(output));
    }

  /// Project ID do Firebase configurado no app.
  static String? _projectId;
  static String get projectId {
    if (_projectId != null) return _projectId!;
    // Reutiliza a config já inicializada pelo Firebase.initializeApp().
    final FirebaseOptions options = Firebase.app().options;
    _projectId = options.projectId;
    return _projectId!;
  }

  static String get _documentsBaseUrl =>
      'https://$_firestoreHost/v1/projects/$projectId/databases/(default)/documents';

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Path raiz dos orçamentos de um dono, no formato do Firestore REST.
  /// `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS`
  static String _orcamentosPath(String ownerUid) =>
      'EMPRESAS/$ownerUid/USERS/$ownerUid/ORCAMENTOS';

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Localiza o orçamento pelo "número do endereço" (document id = `ID`).
  ///
  /// Lança [WebBudgetAccessError] quando o token é inválido/expirado (401/403)
  /// ou o orçamento não existe (404). O telefone **não** é usado para localizar.
  Future<CustomerInfo> getBudget({
    required String ownerUid,
    required String enderecoNumero,
    required String token,
  }) async {
    final url = Uri.parse(
      '$_documentsBaseUrl/${_orcamentosPath(ownerUid)}/$enderecoNumero',
    );
    final response = await http.get(url, headers: _headers(token));
    _ensureOk(response, 'getBudget');
    final fields = _extractFields(response.body);
    final model = CustomerInfo.fromMap(fields);
    // Garante o ID documental mesmo que o campo ID não esteja gravado.
    model.id ??= enderecoNumero;
    return model;
  }

  /// Lista os itens do orçamento (subcoleção `ITENS`), ordenados por
  /// `CATEGORIA`, igual ao app mobile.
  Future<List<ItemsBudget>> getItems({
    required String ownerUid,
    required String enderecoNumero,
    required String token,
  }) async {
    final url = Uri.parse(
      '$_documentsBaseUrl/${_orcamentosPath(ownerUid)}/$enderecoNumero/ITENS'
      '?orderBy=CATEGORIA',
    );
    final response = await http.get(url, headers: _headers(token));
    _ensureOk(response, 'getItems');
    final List<ItemsBudget> items = <ItemsBudget>[];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    for (final doc in (body['documents'] as List?) ?? const []) {
      final docMap = doc as Map<String, dynamic>;
      final fields = _extractFieldsFromDoc(docMap);
      final item = ItemsBudget.fromMap(fields);
      item.id = docMap['name']?.toString().split('/').last;
      item.checkBox = false;
      item.selectProduct = false;
      items.add(item);
    }
    return items;
  }

  /// Dados do titular/empresa (INFOPDF/INFORMATION), reutilizado pelo PDF.
  Future<Map<String, dynamic>> getOwnerInfo({
    required String ownerUid,
    required String token,
  }) async {
    final url = Uri.parse(
      '$_documentsBaseUrl/EMPRESAS/$ownerUid/USERS/$ownerUid/INFOPDF/INFORMATION',
    );
    final response = await http.get(url, headers: _headers(token));
    _ensureOk(response, 'getOwnerInfo');
    return _extractFields(response.body);
  }

  /// Observações/comentários do orçamento, reutilizadas pelo PDF.
  Future<List<ObservationPdf>> getObservations({
    required String ownerUid,
    required String enderecoNumero,
    required String token,
  }) async {
    final url = Uri.parse(
      '$_documentsBaseUrl/${_orcamentosPath(ownerUid)}/$enderecoNumero/OBSERVACAO',
    );
    final response = await http.get(url, headers: _headers(token));
    _ensureOk(response, 'getObservations');
    final List<ObservationPdf> list = <ObservationPdf>[];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    for (final doc in (body['documents'] as List?) ?? const []) {
      final docMap = doc as Map<String, dynamic>;
      final fields = _extractFieldsFromDoc(docMap);
      list.add(ObservationPdf(
        data: (fields['DATA'] ?? '').toString(),
        observacao: (fields['OBSERVACAO'] ?? '').toString(),
      ));
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // Write (status de aprovação — regra de negócio existente: campo STATUS)
  // ---------------------------------------------------------------------------

  /// Atualiza o `STATUS` do orçamento (Aprovado/Reprovado/...). Reutiliza o
  /// mesmo campo/valores usados pelo app mobile — nenhuma regra paralela.
  Future<void> updateStatus({
    required String ownerUid,
    required String enderecoNumero,
    required String token,
    required String status,
  }) async {
    final url = Uri.parse(
      '$_documentsBaseUrl/${_orcamentosPath(ownerUid)}/$enderecoNumero'
      '?updateMask.fieldPaths=STATUS',
    );
    final body = jsonEncode({
      'fields': {
        'STATUS': {'stringValue': status},
      },
    });
    final response = await http.patch(url, headers: _headers(token), body: body);
    _ensureOk(response, 'updateStatus');
  }

  // ---------------------------------------------------------------------------
  // Notificação push ao DONO do orçamento (quem criou/enviou o orçamento)
  // ---------------------------------------------------------------------------

  /// Grava um documento em `EMPRESAS/{ownerUid}/USERS/{ownerUid}/NOTIFICACOES`
  /// avisando que o cliente acabou de aprovar/reprovar o orçamento pela Web.
  ///
  /// O app mobile (do dono) escuta essa coleção em tempo real via Firestore
  /// (`NotificationService`) e exibe uma **notificação local** ao receber um
  /// novo documento — é o "push" que avisa quem criou o orçamento.
  ///
  /// Reutiliza o **mesmo token provisório do Firebase** do dono já usado no
  /// fluxo (camada de segurança do link) e a **mesma coleção base do dono**
  /// já usada pelo app — não cria uma segunda arquitetura de autenticação nem
  /// um novo sistema de push paralelo. A escrita cumpre as regras de segurança
  /// do Firestore (o dono escreve no próprio path com o próprio token).
  ///
  /// Falhas aqui são silenciosas (log only): a aprovação em si já foi gravada
  /// por [updateStatus]; a notificação é best-effort e não deve reverter o
  /// status aprovado.
  Future<void> sendApprovalNotification({
    required String ownerUid,
    required String enderecoNumero,
    required String token,
    required String status,
    required String title,
    required String message,
  }) async {
    try {
      final url = Uri.parse(
        '$_documentsBaseUrl/EMPRESAS/$ownerUid/USERS/$ownerUid/NOTIFICACOES',
      );
      final body = jsonEncode({
        'fields': {
          'TITULO': {'stringValue': title},
          'MENSAGEM': {'stringValue': message},
          'STATUS': {'stringValue': status},
          'ORCAMENTO_ID': {'stringValue': enderecoNumero},
          'CRIADO_EM': {
            'timestampValue': DateTime.now().toUtc().toIso8601String()
          },
          'LIDO': {'booleanValue': false},
        },
      });
      final response =
          await http.post(url, headers: _headers(token), body: body);
      // 200 = criado com ID gerado pelo servidor. Não lança em falha para não
      // reverter a aprovação já gravada.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '[WebBudgetService] sendApprovalNotification falhou: '
            '${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[WebBudgetService] sendApprovalNotification erro: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers REST -> map plano (compatível com os `fromMap` dos models)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _extractFields(String responseBody) {
    final Map<String, dynamic> doc = jsonDecode(responseBody);
    return _extractFieldsFromDoc(doc);
  }

  /// Converte o `{"fields":{...}}` do Firestore REST num mapa plano com as
  /// chaves maiúsculas já esperadas pelos `fromMap` dos models (ID, FONE,
  /// VALORTOTAL, CATEGORIA, ...).
  static Map<String, dynamic> _extractFieldsFromDoc(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>?;
    if (fields == null) return <String, dynamic>{};
    final out = <String, dynamic>{};
    fields.forEach((key, value) {
      out[key] = _unwrap(value as Map<String, dynamic>);
    });
    return out;
  }

  static dynamic _unwrap(Map<String, dynamic> typed) {
    if (typed.containsKey('stringValue')) return typed['stringValue'];
    if (typed.containsKey('integerValue')) {
      final v = typed['integerValue'];
      return v is String ? int.tryParse(v) : v;
    }
    if (typed.containsKey('doubleValue')) {
      final v = typed['doubleValue'];
      return v is String ? double.tryParse(v) : (v as num?)?.toDouble();
    }
    if (typed.containsKey('booleanValue')) return typed['booleanValue'];
    if (typed.containsKey('timestampValue')) return typed['timestampValue'];
    if (typed.containsKey('nullValue')) return null;
    // Fallback: devolve o primeiro valor encontrado.
    return typed.values.first;
  }

  static void _ensureOk(http.Response response, String op) {
    final code = response.statusCode;
    if (code == 401 || code == 403) {
      throw WebBudgetAccessError(
        'Token inválido ou expirado ($op).',
        kind: WebBudgetErrorKind.token,
      );
    }
    if (code == 404) {
      throw WebBudgetAccessError(
        'Orçamento não encontrado ($op).',
        kind: WebBudgetErrorKind.notFound,
      );
    }
    if (code < 200 || code >= 300) {
      debugPrint('[WebBudgetService] $op falhou: $code ${response.body}');
      throw WebBudgetAccessError(
        'Erro de comunicação ($op: $code).',
        kind: WebBudgetErrorKind.unknown,
      );
    }
  }
}

enum WebBudgetErrorKind { token, notFound, unknown }

class WebBudgetAccessError implements Exception {
  final String message;
  final WebBudgetErrorKind kind;
  WebBudgetAccessError(this.message, {required this.kind});

  @override
  String toString() => message;
}
