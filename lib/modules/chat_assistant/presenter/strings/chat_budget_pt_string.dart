import 'package:flutter/widgets.dart';

/// Textos do módulo ChatBudget internacionalizados.
class ChatBudgetStrings {
  const ChatBudgetStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get assistantName => _isPt ? 'Assistente' : 'Assistant';

  static String get online => _isPt ? 'online' : 'online';

  static String get restartTooltip =>
      _isPt ? 'Reiniciar conversa' : 'Restart conversation';

  static String get shareErrorDefault =>
      _isPt ? 'Erro ao compartilhar' : 'Error sharing';

  static String get finalizeAndGenerateLink =>
      _isPt ? 'Finalizar e gerar link' : 'Finalize and generate link';

  static String get editingMessage =>
      _isPt ? 'Editando mensagem' : 'Editing message';

  static String get streetField => _isPt ? 'Rua' : 'Street';

  static String get numberField => _isPt ? 'Número' : 'Number';

  static String get cityField => _isPt ? 'Cidade' : 'City';

  static String get cancelAndProceed =>
      _isPt
          ? 'Cancelar e seguir com a geração do orçamento'
          : 'Cancel and proceed with budget generation';

  static String get clientFallback => _isPt ? 'Cliente' : 'Client';

  static String get typeOptionInstruction =>
      _isPt ? 'Toque na opção desejada' : 'Tap the desired option';

  static String get budgetNotAvailable =>
      _isPt
          ? 'Orçamento não disponível para compartilhar'
          : 'Budget not available for sharing';

  static String get tapAndHoldToEdit =>
      _isPt ? 'Toque e segure para editar' : 'Tap and hold to edit';

  static String get contactPickerHint =>
      _isPt
          ? 'Selecione nos contatos ou escreva no campo abaixo e me envie'
          : 'Select from contacts or type in the field below and send me';

  // ------------------------------------------------------------------
  // Menu principal do chat (estilo bot WhatsApp)
  // ------------------------------------------------------------------
  static String get mainMenuQuestion =>
      _isPt ? 'O que eu posso fazer por você?' : 'What can I do for you?';

  static List<String> get mainMenuOptionLabels =>
      _isPt
          ? const [
            'Criar orçamentos',
            'Cadastrar produtos e serviços',
            'Editar PDF',
            'Trocar nome de usuário',
          ]
          : const [
            'Create budget',
            'Price list',
            'Edit PDF',
            'Change username',
          ];

  static String get menuInvalidOption =>
      _isPt
          ? 'Opção inválida. Toque em uma das opções acima.'
          : 'Invalid option. Tap one of the options above.';

  static String get menuBackLabel => _isPt ? 'Voltar ao menu' : 'Back to menu';

  // ------------------------------------------------------------------
  // Assistente com IA (assinantes)
  // ------------------------------------------------------------------
  static String get aiFallback =>
      _isPt
          ? 'Não consegui entender agora 😕 Escolha uma das opções abaixo.'
          : "I couldn't understand that right now 😕 Pick one of the options below.";

  static String get aiTyping => _isPt ? 'digitando…' : 'typing…';

  static String aiSystemPrompt({
    required String today,
    required String userName,
  }) => '''
Você é o assistente do OFLite, app de orçamentos e recibos para prestadores de serviço.
Hoje é $today. Usuário: ${userName.isEmpty ? 'não informado' : userName}.

O que o app faz pelo menu deste chat:
1 - Criar orçamento (cliente, telefone, endereço, produtos, observações, link para o cliente)
2 - Lista de preços (ver/cadastrar produtos)
3 - Editar dados do PDF (nome da empresa, telefone, e-mail, CNPJ, endereço, logo)
4 - Alterar nome de usuário
Status de orçamento: PENDENTE, APROVADO, REPROVADO, FINALIZADO.

Regras:
1. Responda no idioma do usuário (${_isPt ? 'português do Brasil' : 'English'} por padrão), em no máximo 3 frases curtas.
2. Quando o usuário quiser fazer uma das ações do menu, chame a ferramenta start_flow com o fluxo certo, sem perguntar antes. Se não estiver claro qual ação, pergunte de forma curta.
3. Você ainda NÃO consegue consultar nem alterar orçamentos. Nunca invente números, nomes ou orçamentos.
4. Fora do escopo do app, diga educadamente o que você sabe fazer.
5. Texto puro: não use markdown (nada de **, #, listas com -).
''';

  static List<String> get yesNoOptionLabels =>
      _isPt ? const ['Sim', 'Não'] : const ['Yes', 'No'];

  static String get budgetTransition =>
      _isPt ? 'Vamos lá! 💪' : 'Let\'s go! 💪';

  // ------------------------------------------------------------------
  // Lista de preço
  // ------------------------------------------------------------------
  static String get priceListMenuQuestion =>
      _isPt
          ? 'Legal, o que você quer fazer?'
          : 'Great, what do you want to do?';

  static List<String> get priceListMenuOptionLabels =>
      _isPt
          ? const ['Ver lista de produtos', 'Adicionar um novo produto']
          : const ['View product list', 'Add new product'];

  // ------------------------------------------------------------------
  // Editar PDF
  // ------------------------------------------------------------------
  static String get pdfEditMenuQuestion =>
      _isPt
          ? 'Qual informação do PDF você quer mudar?'
          : 'Which PDF information do you want to change?';

  static List<String> get pdfEditMenuOptionLabels =>
      _isPt
          ? const [
            'Nome da empresa',
            'Telefone',
            'Email',
            'CNPJ',
            'Endereço',
            'Logo',
            'Modelo de PDF',
          ]
          : const [
            'Company name',
            'Phone',
            'Email',
            'CNPJ',
            'Address',
            'Logo',
            'PDF Model',
          ];

  static String get pdfEditNextQuestion =>
      _isPt ? 'O que você quer fazer agora?' : 'What do you want to do now?';

  static List<String> get pdfEditNextOptionLabels =>
      _isPt
          ? const ['Continuar editando PDF', 'Voltar ao menu principal']
          : const ['Keep editing PDF', 'Back to main menu'];

  static String get pdfEditAskName =>
      _isPt ? 'Digite o novo nome da empresa:' : 'Enter the new company name:';

  static String get pdfEditAskPhone =>
      _isPt
          ? 'Digite o novo telefone da empresa (com DDD):'
          : 'Enter the new company phone (with area code):';

  static String get pdfEditAskEmail =>
      _isPt ? 'Digite o novo email:' : 'Enter the new email:';

  static String get pdfEditAskCnpj =>
      _isPt ? 'Digite o novo CNPJ:' : 'Enter the new CNPJ:';

  static String get pdfEditInvalidPhone =>
      _isPt
          ? 'Telefone inválido. Informe apenas números com DDD.'
          : 'Invalid phone. Enter only numbers with area code.';

  static String get pdfEditInvalidEmail =>
      _isPt
          ? 'Email inválido. Informe um email válido.'
          : 'Invalid email. Enter a valid email.';

  static String get pdfEditInvalidCnpj =>
      _isPt
          ? 'CNPJ inválido. Informe 14 números.'
          : 'Invalid CNPJ. Enter 14 numbers.';

  static String get pdfEditSuccessName =>
      _isPt
          ? 'Nome da empresa atualizado com sucesso para:'
          : 'Company name successfully updated to:';

  static String get pdfEditSuccessPhone =>
      _isPt
          ? 'Telefone atualizado com sucesso:'
          : 'Phone successfully updated:';

  static String get pdfEditSuccessEmail =>
      _isPt ? 'Email atualizado com sucesso:' : 'Email successfully updated:';

  static String get pdfEditSuccessCnpj =>
      _isPt ? 'CNPJ atualizado com sucesso:' : 'CNPJ successfully updated:';

  static String get pdfEditSuccessAddress =>
      _isPt
          ? 'Endereço atualizado com sucesso.'
          : 'Address successfully updated.';

  static String get pdfModelSelected =>
      _isPt ? 'Novo modelo de PDF selecionado' : 'New PDF model selected';

  static String get pdfModelSelectError =>
      _isPt
          ? 'Não foi possível salvar o modelo de PDF. Tente novamente.'
          : 'Could not save the PDF model. Please try again.';

  static String get pdfEditAskHasCep =>
      _isPt
          ? 'Vamos atualizar o endereço da sua empresa. Você tem o CEP?'
          : 'Let\'s update your company address. Do you have the ZIP code?';

  static String get pdfEditProceedQuestion =>
      _isPt
          ? 'Deseja prosseguir com a alteração?'
          : 'Do you want to proceed with the changes?';

  // ------------------------------------------------------------------
  // Logo submenu
  // ------------------------------------------------------------------
  static String get logoNotFound =>
      _isPt
          ? 'Você ainda não tem uma logo cadastrada.'
          : "You don't have a logo yet.";

  static String get logoCaption =>
      _isPt ? 'Logo da sua empresa:' : 'Your company logo:';

  static String get logoChangeLabel => _isPt ? 'Alterar logo' : 'Change logo';

  static String get logoMenuQuestion =>
      _isPt
          ? 'O que você quer fazer com a logo?'
          : 'What do you want to do with the logo?';

  static List<String> get logoMenuOptionLabels =>
      _isPt
          ? const ['Ver logo da empresa', 'Inserir/Alterar logo']
          : const ['View company logo', 'Insert/Change logo'];

  // ------------------------------------------------------------------
  // Trocar nome de usuário
  // ------------------------------------------------------------------
  static String get changeUsernameInstructions =>
      _isPt
          ? 'Vou abrir o modal para você alterar o nome de usuário.'
          : 'I will open the modal so you can change your username.';

  static List<String> get changeUsernameMenuOptionLabels =>
      _isPt ? const ['Alterar nome de usuário'] : const ['Change username'];

  static String get changeUsernameSuccess =>
      _isPt
          ? 'Nome de usuário atualizado com sucesso para:'
          : 'Username successfully updated to:';

  static String get changeUsernameCancelled =>
      _isPt ? 'Ok, deixei como está.' : 'Okay, I left it as is.';

  static String get changeUsernameNotChanged =>
      _isPt
          ? 'Você não alterou o nome de usuário.'
          : 'You did not change the username.';

  static String get changeUsernameRetryQuestion =>
      _isPt ? 'O que você quer fazer agora?' : 'What do you want to do now?';

  static List<String> get changeUsernameRetryOptionLabels =>
      _isPt
          ? const ['Trocar novamente', 'Voltar ao menu principal']
          : const ['Change again', 'Back to main menu'];
}
