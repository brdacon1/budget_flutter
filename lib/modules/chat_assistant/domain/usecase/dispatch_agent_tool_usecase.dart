import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/entity/budget_filter.dart';
import 'package:oflite/modules/budget/domain/entity/budget_status.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/modules/budget/domain/usecase/get_month_summary_usecase.dart';
import 'package:oflite/modules/budget/domain/usecase/list_budgets_usecase.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/chat_message_entity.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/receipt/domain/entity/receipts_report.dart';
import 'package:oflite/modules/receipt/domain/usecase/get_receipts_report_usecase.dart';
import 'package:oflite/modules/receipt/domain/usecase/list_receipts_by_budget_usecase.dart';
import 'package:oflite/modules/receipt/presenter/strings/payment_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Declara as tools do agente e executa a que o modelo pediu.
///
/// Leitura → executa e devolve um JSON enxuto ao modelo + cards para o chat.
/// Escrita → só valida e devolve a ação pendente (o usuário confirma no card;
/// quem grava é o `ConfirmAgentActionUsecase`). Argumento inválido vira
/// `{error: ...}` para o modelo se corrigir sozinho.
class DispatchAgentToolUsecase {
  final ListBudgetsUsecase _listBudgets;
  final GetMonthSummaryUsecase _monthSummary;
  final ListReceiptsByBudgetUsecase _listReceipts;
  final BudgetRepository _budgetRepo;
  final ShareLinkRepository _shareLink;
  final ConvertCoinRepository _coin;
  final GetReceiptsReportUsecase _receiptsReport;

  const DispatchAgentToolUsecase(
    this._listBudgets,
    this._monthSummary,
    this._listReceipts,
    this._budgetRepo,
    this._shareLink,
    this._coin,
    this._receiptsReport,
  );

  // Nomes das tools.
  static const startFlow = 'start_flow';
  static const listBudgets = 'list_budgets';
  static const monthSummary = 'get_month_summary';
  static const listReceipts = 'list_receipts';
  static const budgetLink = 'get_budget_link';
  static const openBudget = 'open_budget';
  static const createReceipt = 'create_receipt';
  static const updateStatus = 'update_budget_status';
  static const receiptsReport = 'get_receipts_report';

  /// Máximo de itens devolvidos ao modelo (a lista completa vai para a UI).
  static const _maxItemsToModel = 20;

  /// Valores fixos do arg `purpose` de `list_budgets` (nunca traduzir).
  static const purposeReceipts = 'receipts';
  static const purposeView = 'view';
  static const purposeDuplicate = 'duplicate';

  /// Navegação/ação que abre o modal de seleção de orçamento para recibo.
  static const selectReceiptBudget = 'select_receipt_budget';

  /// Navegação/ação que abre o modal de seleção de orçamento para duplicar.
  static const selectDuplicateBudget = 'select_duplicate_budget';

  /// Fluxo do menu (valor enviado pela IA) → opção do menu principal.
  static const flowToMenuOption = {
    'create_budget': '1',
    'price_list': '2',
    'pdf_edit': '3',
    'change_username': '4',
  };

  static final _statusValues = [for (final s in BudgetStatus.values) s.value];
  static const _budgetIdParam = {
    'type': 'string',
    'description': 'id do orçamento (vem de list_budgets)',
    'required': true,
  };

  List<AgentToolSpec> get tools => [
    AgentToolSpec(
      startFlow,
      'Abre um fluxo guiado do app: create_budget (criar orçamento), '
      'price_list (ver/cadastrar produtos e serviços), pdf_edit (editar '
      'dados/logo do PDF), change_username (trocar nome de usuário).',
      {
        'flow': {
          'type': 'enum',
          'values': flowToMenuOption.keys.toList(),
          'required': true,
        },
      },
    ),
    AgentToolSpec(
      listBudgets,
      'Lista orçamentos do usuário com filtros. Devolve id, cliente, valor, '
      'status e data, além da quantidade e do total formatado.',
      {
        'status': {'type': 'enum', 'values': _statusValues},
        'from': {'type': 'string', 'description': 'data inicial yyyy-MM-dd'},
        'to': {'type': 'string', 'description': 'data final yyyy-MM-dd'},
        'client_name': {
          'type': 'string',
          'description': 'parte do nome do cliente',
        },
        'purpose': {
          'type': 'enum',
          'values': [purposeView, purposeReceipts, purposeDuplicate],
          'description':
              'use "receipts" quando o usuário precisa escolher o orçamento '
              'para criar/ver recibos, "duplicate" para duplicar/clonar um '
              'orçamento (ambos abrem um modal de seleção); senão "view"',
        },
      },
    ),
    AgentToolSpec(
      monthSummary,
      'Resumo de um mês: quantidade e valor total de orçamentos, por status.',
      {
        'month': {
          'type': 'string',
          'description': 'mês yyyy-MM',
          'required': true,
        },
      },
    ),
    AgentToolSpec(
      listReceipts,
      'Lista os recibos de um orçamento com o valor pago em cada um.',
      {'budget_id': _budgetIdParam},
    ),
    AgentToolSpec(
      receiptsReport,
      'Relatório de recibos de TODOS os orçamentos num período (semana, mês, '
      'intervalo): quantidade, valor emitido e valor recebido (pagamentos).',
      {
        'from': {
          'type': 'string',
          'description': 'data inicial yyyy-MM-dd (semana começa na segunda)',
          'required': true,
        },
        'to': {
          'type': 'string',
          'description': 'data final yyyy-MM-dd (inclusive)',
          'required': true,
        },
        'group_by': {
          'type': 'enum',
          'values': [for (final g in ReceiptsReportGroupBy.values) g.value],
          'description': 'quebra por dia ou semana; auto se não pedido',
        },
        'compare_previous': {
          'type': 'boolean',
          'description': 'compara com o período anterior de mesmo tamanho',
        },
      },
    ),
    AgentToolSpec(
      budgetLink,
      'Gera o link público do orçamento para enviar ao cliente.',
      {'budget_id': _budgetIdParam},
    ),
    AgentToolSpec(
      openBudget,
      'Abre a tela do orçamento (itens, PDF, recibos).',
      {'budget_id': _budgetIdParam},
    ),
    AgentToolSpec(
      createReceipt,
      'Cria um recibo vinculado a um orçamento, opcionalmente já com o '
      'pagamento recebido. Pede confirmação ao usuário antes de gravar.',
      {
        'budget_id': _budgetIdParam,
        'description': {
          'type': 'string',
          'description': 'descrição do recibo (ex.: Entrada, Parcela 1)',
          'required': true,
        },
        'amount': {'type': 'number', 'description': 'valor recebido'},
        'method': {
          'type': 'enum',
          'values': PaymentStrings.paymentTypeOptions,
          'description': 'forma de pagamento',
        },
      },
    ),
    AgentToolSpec(
      updateStatus,
      'Altera o status de um orçamento. Pede confirmação antes de gravar.',
      {
        'budget_id': _budgetIdParam,
        'status': {'type': 'enum', 'values': _statusValues, 'required': true},
      },
    ),
  ];

  Future<AgentToolOutcome> call(AgentToolCallEntity call) async {
    final args = call.args;
    try {
      return switch (call.name) {
        startFlow => _startFlow(args),
        listBudgets => await _list(args),
        monthSummary => await _summary(args),
        listReceipts => await _receipts(args),
        receiptsReport => await _report(args),
        budgetLink => await _link(args),
        openBudget => await _open(args),
        createReceipt => await _previewReceipt(args),
        updateStatus => await _previewStatus(args),
        _ => _error('unknown_tool'),
      };
    } on FormatException catch (e) {
      return _error(e.message);
    }
  }

  // ------------------------------------------------------------------
  // Leitura
  // ------------------------------------------------------------------

  AgentToolOutcome _startFlow(Map<String, Object?> args) {
    final option = flowToMenuOption[args['flow']];
    if (option == null) return _error('invalid_flow');
    return AgentToolOutcome(
      modelPayload: {'opened': args['flow']},
      menuOption: option,
    );
  }

  Future<AgentToolOutcome> _list(Map<String, Object?> args) async {
    if (args['purpose'] == purposeReceipts) {
      return _selectBudget(
        selectReceiptBudget,
        ChatAssistantStrings.aiSelectReceiptBudget,
      );
    }
    if (args['purpose'] == purposeDuplicate) {
      return _selectBudget(
        selectDuplicateBudget,
        ChatAssistantStrings.aiSelectDuplicateBudget,
      );
    }
    final status =
        args['status'] == null
            ? null
            : BudgetStatus.fromValue(args['status'] as String);
    if (args['status'] != null && status == null) {
      return _error('invalid_status');
    }
    final result = await _listBudgets(
      BudgetFilter(
        status: status,
        from: _date(args['from']),
        to: _date(args['to']),
        clientName: args['client_name'] as String?,
      ),
    );
    if (result case Error()) return _error('fetch_failed');
    final budgets = (result as Ok<List<CustomerInfo>>).value;
    final total = budgets.fold<double>(0, (s, b) => s + (b.totalValue ?? 0));
    final totalFmt = _coin.convertFromDouble(total);

    return AgentToolOutcome(
      modelPayload: {
        'count': budgets.length,
        'total': totalFmt,
        'items': [
          for (final b in budgets.take(_maxItemsToModel))
            {
              'id': b.id,
              'cliente': b.customerName,
              'valor': _coin.convertFromDouble(b.totalValue ?? 0),
              'status': b.status,
              'data': b.data,
            },
        ],
      },
      messages:
          budgets.isEmpty
              ? const []
              : [
                _card(ChatMessageType.budgetList, {
                  'title': ChatAssistantStrings.aiBudgetListTitle,
                  'footer': ChatAssistantStrings.aiBudgetListFooter(
                    budgets.length,
                    totalFmt,
                  ),
                  'items': [
                    for (final b in budgets)
                      {
                        'id': b.id,
                        'name': b.customerName ?? '',
                        'value': _coin.convertFromDouble(b.totalValue ?? 0),
                        'status': b.status ?? '',
                        'date': b.data ?? '',
                      },
                  ],
                }),
              ],
    );
  }

  /// Recibo/duplicar sem orçamento escolhido: em vez do card, abre o modal de
  /// seleção e deixa no chat a mensagem com "Selecionar orçamento" / voltar
  /// ao menu. [action] diz o que acontece após a escolha.
  AgentToolOutcome _selectBudget(String action, String text) {
    final now = DateTime.now();
    return AgentToolOutcome(
      modelPayload: const {'shown': 'budget_picker'},
      messages: [
        ChatMessageEntity(
          id: '${now.microsecondsSinceEpoch}',
          sender: ChatSender.bot,
          type: ChatMessageType.action,
          content: text,
          payload: {
            'label': ChatAssistantStrings.aiSelectBudgetLabel,
            'action': action,
            'backLabel': ChatAssistantStrings.menuBackLabel,
          },
          timestamp: now,
        ),
      ],
      navigation: action,
    );
  }

  Future<AgentToolOutcome> _summary(Map<String, Object?> args) async {
    final raw = args['month'] as String? ?? '';
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
    if (match == null) return _error('month must be yyyy-MM');
    final month = DateTime(int.parse(match[1]!), int.parse(match[2]!));

    final result = await _monthSummary(month);
    if (result case Error()) return _error('fetch_failed');
    final s = (result as Ok<MonthSummary>).value;
    final monthLabel = '${match[2]}/${match[1]}';

    return AgentToolOutcome(
      modelPayload: {
        'month': raw,
        'count': s.count,
        'total': _coin.convertFromDouble(s.total),
        'by_status': {
          for (final e in s.byStatus.entries)
            e.key: {
              'count': e.value.count,
              'total': _coin.convertFromDouble(e.value.total),
            },
        },
      },
      messages: [
        _card(ChatMessageType.summaryCard, {
          'title': ChatAssistantStrings.aiSummaryTitle(monthLabel),
          'totalLabel': ChatAssistantStrings.aiSummaryTotal,
          'total': _coin.convertFromDouble(s.total),
          'count': s.count,
          'rows': [
            for (final e in s.byStatus.entries)
              {
                'status': e.key,
                'label': ChatAssistantStrings.budgetStatusLabel(e.key),
                'count': e.value.count,
                'total': _coin.convertFromDouble(e.value.total),
              },
          ],
        }),
      ],
    );
  }

  Future<AgentToolOutcome> _receipts(Map<String, Object?> args) async {
    final budget = await _budget(args);
    if (budget == null) return _error('budget_not_found');
    final result = await _listReceipts(budget.id!);
    if (result case Error()) return _error('fetch_failed');
    final list = (result as Ok<List<ReceiptWithTotal>>).value;
    final paid = list.fold<double>(0, (s, r) => s + r.paid);
    final total = budget.totalValue ?? 0;
    return AgentToolOutcome(
      modelPayload: {
        'cliente': budget.customerName,
        'valor_orcamento': _coin.convertFromDouble(total),
        'total_recebido': _coin.convertFromDouble(paid),
        'saldo': _coin.convertFromDouble(total - paid),
        'recibos': [
          for (final r in list.take(_maxItemsToModel))
            {
              'id': r.receipt.id,
              'descricao': r.receipt.descricao,
              'data': r.receipt.data,
              'pago': _coin.convertFromDouble(r.paid),
            },
        ],
      },
    );
  }

  Future<AgentToolOutcome> _report(Map<String, Object?> args) async {
    final from = _date(args['from']);
    final to = _date(args['to']);
    if (from == null || to == null) return _error('from_and_to_required');
    final groupBy = ReceiptsReportGroupBy.fromValue(
      args['group_by'] as String?,
    );
    if (groupBy == null) return _error('invalid_group_by');

    final result = await _receiptsReport(
      ReceiptsReportFilter(
        from: from,
        to: to,
        groupBy: groupBy,
        comparePrevious: args['compare_previous'] == true,
      ),
    );
    if (result case Error(:final error)) {
      return _error(
        error is FormatException
            ? error.message
            : 'receipts_report_unavailable',
      );
    }
    final r = (result as Ok<ReceiptsReport>).value;
    final money = _coin.convertFromDouble;
    final change = r.paidChangePercent?.round();
    final top = r.topBudgets.firstOrNull;

    return AgentToolOutcome(
      modelPayload: {
        'count': r.count,
        'issued': money(r.issued),
        'paid': money(r.paid),
        if (r.previous != null)
          'previous': {
            'count': r.previous!.count,
            'paid': money(r.previous!.paid),
          },
        if (change != null) 'paid_change_percent': change,
        if (top != null) 'top_client': top.client,
      },
      messages: [
        _card(ChatMessageType.receiptsReportCard, {
          'title': ChatAssistantStrings.aiReceiptsReportTitle(
            _dm(r.from),
            _dm(r.to),
          ),
          'countLabel': ChatAssistantStrings.aiReceiptsCountLabel,
          'count': r.count,
          'issuedLabel': ChatAssistantStrings.aiReceiptsIssuedLabel,
          'issued': money(r.issued),
          'paidLabel': ChatAssistantStrings.aiReceiptsPaidLabel,
          'paid': money(r.paid),
          if (r.previous != null)
            'previous': ChatAssistantStrings.aiReceiptsPrevious(
              r.previous!.count,
              money(r.previous!.paid),
            ),
          if (change != null) 'change': change,
          'buckets': [
            for (final b in r.buckets)
              {
                'label':
                    r.groupBy == ReceiptsReportGroupBy.day
                        ? _dm(b.start)
                        : '${_dm(b.start)}–${_dm(b.end)}',
                'count': b.count,
                'paid': money(b.paid),
                'paidRaw': b.paid,
              },
          ],
          'topLabel': ChatAssistantStrings.aiReceiptsTopLabel,
          'top': [
            for (final t in r.topBudgets)
              {
                'id': t.budgetId,
                'name': t.client,
                'count': t.count,
                'paid': money(t.paid),
              },
          ],
        }),
      ],
    );
  }

  static String _dm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<AgentToolOutcome> _link(Map<String, Object?> args) async {
    final budget = await _budget(args);
    if (budget == null) return _error('budget_not_found');
    final url = await _shareLink.buildShareUrl(enderecoNumero: budget.id!);
    if (url == null || url.isEmpty) return _error('link_failed');
    return AgentToolOutcome(
      modelPayload: {'ok': true, 'cliente': budget.customerName},
      messages: [
        _card(ChatMessageType.action, {
          'label': ChatAssistantStrings.aiShareLinkLabel,
          'action': 'share_url|$url',
        }),
      ],
    );
  }

  Future<AgentToolOutcome> _open(Map<String, Object?> args) async {
    final budget = await _budget(args);
    if (budget == null) return _error('budget_not_found');
    return AgentToolOutcome(
      modelPayload: {'opened': true, 'cliente': budget.customerName},
      navigation: 'open_budget|${budget.id}',
    );
  }

  // ------------------------------------------------------------------
  // Escrita (só prévia — grava após confirmação)
  // ------------------------------------------------------------------

  Future<AgentToolOutcome> _previewReceipt(Map<String, Object?> args) async {
    final budget = await _budget(args);
    if (budget == null) return _error('budget_not_found');
    final description = (args['description'] as String? ?? '').trim();
    if (description.isEmpty) return _error('description_required');
    final amount = (args['amount'] as num?)?.toDouble();
    if (amount != null && amount <= 0) return _error('amount_must_be_positive');
    final method = args['method'] as String?;
    if (method != null && !PaymentStrings.paymentTypeOptions.contains(method)) {
      return _error('invalid_method');
    }

    final client = budget.customerName ?? '';
    return AgentToolOutcome(
      modelPayload: const {'status': 'awaiting_user_confirmation'},
      pending: AgentPendingAction(createReceipt, {
        'budget_id': budget.id,
        'client': client,
        'description': description,
        if (amount != null) 'amount': amount,
        if (method != null) 'method': method,
      }),
      previewText: ChatAssistantStrings.aiReceiptPreview(
        client: client,
        description: description,
        amount: amount == null ? null : _coin.convertFromDouble(amount),
        method: method,
      ),
    );
  }

  Future<AgentToolOutcome> _previewStatus(Map<String, Object?> args) async {
    final budget = await _budget(args);
    if (budget == null) return _error('budget_not_found');
    final status = BudgetStatus.fromValue(args['status'] as String?);
    if (status == null) return _error('invalid_status');
    final client = budget.customerName ?? '';
    return AgentToolOutcome(
      modelPayload: const {'status': 'awaiting_user_confirmation'},
      pending: AgentPendingAction(updateStatus, {
        'budget_id': budget.id,
        'client': client,
        'status': status.value,
      }),
      previewText: ChatAssistantStrings.aiStatusPreview(client, status.value),
    );
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Future<CustomerInfo?> _budget(Map<String, Object?> args) async {
    final id = (args['budget_id'] as String? ?? '').trim();
    if (id.isEmpty) return null;
    final result = await _budgetRepo.getBudgetById(id);
    return switch (result) {
      Ok(:final value) when value.id != null => value,
      _ => null,
    };
  }

  /// `yyyy-MM-dd` → DateTime. Inválida → [FormatException] (vira erro p/ IA).
  DateTime? _date(Object? raw) {
    if (raw == null || raw == '') return null;
    final d = DateTime.tryParse(raw as String);
    if (d == null) throw const FormatException('date must be yyyy-MM-dd');
    return d;
  }

  AgentToolOutcome _error(String code) =>
      AgentToolOutcome(modelPayload: {'error': code});

  ChatMessageEntity _card(ChatMessageType type, Map<String, dynamic> payload) {
    final now = DateTime.now();
    return ChatMessageEntity(
      id: '${now.microsecondsSinceEpoch}',
      sender: ChatSender.bot,
      type: type,
      content: '',
      payload: payload,
      timestamp: now,
    );
  }
}
