import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_message_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/entity/agent_tool_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_ai_repository.dart';
import 'package:oflite/modules/chat_assistant/presenter/strings/chat_budget_pt_string.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Processa uma mensagem livre do usuário com a IA.
///
/// O modelo responde com texto ou pede a tool `start_flow`, que abre o mesmo
/// fluxo determinístico das opções do menu (handoff — nada é reescrito).
class RunAgentTurnUsecase {
  final ChatAiRepository _aiRepo;
  final UserRepository _userRepo;

  const RunAgentTurnUsecase(this._aiRepo, this._userRepo);

  static const startFlowTool = 'start_flow';

  /// Fluxo (valor enviado pela IA) → opção do menu principal.
  static const flowToMenuOption = {
    'create_budget': '1',
    'price_list': '2',
    'pdf_edit': '3',
    'change_username': '4',
  };

  static final tools = [
    AgentToolSpec(
      startFlowTool,
      'Abre um fluxo guiado do app quando o usuário quer executar uma ação: '
      'create_budget (criar orçamento), price_list (ver/cadastrar produtos '
      'e serviços), pdf_edit (editar dados/logo do PDF), change_username '
      '(trocar nome de usuário).',
      {
        'flow': {
          'type': 'enum',
          'values': flowToMenuOption.keys.toList(),
          'description': 'Fluxo a abrir.',
        },
      },
    ),
  ];

  Future<Result<AgentTurnResult>> call(String userText, {DateTime? now}) async {
    _aiRepo.addMessage(AgentMessageEntity(AgentRole.user, userText));

    final system = ChatBudgetStrings.aiSystemPrompt(
      today: _isoDate(now ?? DateTime.now()),
      userName: _userRepo.selectUser.value?.name ?? '',
    );

    final result = await _aiRepo.send(system, tools: tools);
    if (result case Error(:final error)) return Result.error(error);
    final reply = (result as Ok<AgentReplyEntity>).value;

    for (final call in reply.toolCalls) {
      final option =
          call.name == startFlowTool
              ? flowToMenuOption[call.args['flow']]
              : null;
      if (option == null) continue; // tool/arg desconhecido: ignora
      // Registra como texto para o histórico seguir válido sem functionResponse.
      _aiRepo.addMessage(
        AgentMessageEntity(
          AgentRole.model,
          '[abri o fluxo ${call.args['flow']}]',
        ),
      );
      return Result.ok(AgentTurnResult(menuOption: option));
    }

    final text = reply.text.trim();
    if (text.isEmpty) return Result.error(Exception('empty_ai_response'));
    _aiRepo.addMessage(AgentMessageEntity(AgentRole.model, text));
    return Result.ok(AgentTurnResult(text: text));
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
