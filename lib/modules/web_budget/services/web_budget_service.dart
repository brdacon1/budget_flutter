import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/items_budget_model.dart';
import 'package:oflite/modules/budget/data/model/observation_pdf_model.dart';
import 'package:oflite/shared/common/utils/dio_client.dart';

/// Acesso aos dados do orçamento no fluxo **Web público**.
///
/// O link é `https://dominio/o/{code}`: um código curto, com escopo de UM
/// orçamento, criado pelo app do dono (`createShareLink`). A Web não tem
/// token de usuário nenhum — fala só com as Cloud Functions:
///
/// - `openShareLink(code, phone)` → o telefone é validado no **servidor** e
///   só então vêm os dados daquele orçamento;
/// - `respondShareLink(code, phone, status)` → altera apenas o `STATUS` e
///   cria a notificação do dono.
class WebBudgetService {
  static const String functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue:
        'https://southamerica-east1-orcamentofacil-lite.cloudfunctions.net',
  );

  final Dio _dio = DioClient().dioClient;

  /// Extrai o código de `/o/{code}`. `null` se a URL não for um link válido.
  static String? codeFromUri(Uri url) {
    final segments = url.pathSegments;
    final i = segments.indexOf('o');
    if (i < 0 || i + 1 >= segments.length) return null;
    final code = segments[i + 1];
    return RegExp(r'^[A-Za-z0-9_-]{16}$').hasMatch(code) ? code : null;
  }

  Future<SharedBudget> open({
    required String code,
    required String phone,
  }) async {
    final data = await _post('openShareLink', {'code': code, 'phone': phone});

    final items = <ItemsBudget>[];
    for (final raw in (data['items'] as List? ?? const [])) {
      final map = Map<String, dynamic>.from(raw as Map);
      final item = ItemsBudget.fromMap(map);
      item.id = map['id']?.toString();
      item.checkBox = false;
      item.selectProduct = false;
      items.add(item);
    }

    final observations = <ObservationPdf>[
      for (final raw in (data['observations'] as List? ?? const []))
        ObservationPdf(
          data: ((raw as Map)['DATA'] ?? '').toString(),
          observacao: (raw['OBSERVACAO'] ?? '').toString(),
        ),
    ];

    final budgetId = data['budgetId'].toString();
    final budget = CustomerInfo.fromMap(
      Map<String, dynamic>.from(data['budget'] as Map),
    );
    budget.id ??= budgetId;

    return SharedBudget(
      budget: budget,
      items: items,
      observations: observations,
      owner: Map<String, dynamic>.from(data['owner'] as Map? ?? const {}),
    );
  }

  /// Aprova/reprova (`APROVADO`/`REPROVADO`). A notificação ao dono é criada
  /// pela própria Function.
  Future<void> respond({
    required String code,
    required String phone,
    required String status,
    required String title,
    required String message,
  }) async {
    await _post('respondShareLink', {
      'code': code,
      'phone': phone,
      'status': status,
      'title': title,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> _post(
    String function,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post(
        '$functionsBaseUrl/$function',
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true,
        ),
      );
    } catch (e) {
      debugPrint('[WebBudgetService] $function erro: $e');
      throw WebBudgetAccessError(
        'Erro de comunicação ($function).',
        kind: WebBudgetErrorKind.unknown,
      );
    }

    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    if (response.statusCode == 200 && data['ok'] == true) return data;

    debugPrint('[WebBudgetService] $function ${response.statusCode}: $data');
    final kind = switch (data['error']) {
      'phone' => WebBudgetErrorKind.phone,
      'locked' => WebBudgetErrorKind.locked,
      'invalid' || 'expired' || 'revoked' => WebBudgetErrorKind.invalidLink,
      _ => WebBudgetErrorKind.unknown,
    };
    throw WebBudgetAccessError(
      'Falha em $function (${response.statusCode}).',
      kind: kind,
    );
  }
}

/// Dados de um orçamento liberado pelo link.
class SharedBudget {
  const SharedBudget({
    required this.budget,
    required this.items,
    required this.observations,
    required this.owner,
  });

  final CustomerInfo budget;
  final List<ItemsBudget> items;
  final List<ObservationPdf> observations;
  final Map<String, dynamic> owner;
}

enum WebBudgetErrorKind { phone, locked, invalidLink, unknown }

class WebBudgetAccessError implements Exception {
  final String message;
  final WebBudgetErrorKind kind;

  WebBudgetAccessError(this.message, {required this.kind});

  @override
  String toString() => message;
}
