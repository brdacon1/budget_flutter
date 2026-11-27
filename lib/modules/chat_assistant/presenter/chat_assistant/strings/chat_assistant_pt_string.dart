import 'package:flutter/widgets.dart';
import 'package:oflite/modules/pdf/domain/usecase/document/document_validation_result.dart';

/// Textos da tela do assistente (chat) — e dos usecases que montam as
/// mensagens dela.
class ChatAssistantStrings {
  const ChatAssistantStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get assistantName => _isPt ? 'Assistente' : 'Assistant';

  static String get online => _isPt ? 'online' : 'online';

  static String get emptyDetailHint =>
      _isPt
          ? 'O que o assistente abrir aparece aqui'
          : 'Whatever the assistant opens shows up here';

  static String get restartTooltip =>
      _isPt ? 'Reiniciar conversa' : 'Restart conversation';

  static String get shareErrorDefault =>
      _isPt ? 'Erro ao compartilhar' : 'Error sharing';

  static String get finalizeAndGenerateLink =>
      _isPt ? 'Finalizar e gerar link' : 'Gerar orçamento';

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

  /// Pergunta do menu enquanto o usuário ainda não começou o 1º orçamento.
  static String get firstBudgetMenuQuestion =>
      _isPt
          ? 'Vamos criar seu primeiro orçamento?'
          : 'Ready to create your first budget?';

  static List<String> get mainMenuOptionLabels =>
      _isPt
          ? const [
            '📝 Criar orçamentos',
            '📦 Cadastrar produtos e serviços',
            '📄 Editar PDF',
            '👤 Trocar nome de usuário',
          ]
          : const [
            '📝 Create budget',
            '📦 Price list',
            '📄 Edit PDF',
            '👤 Change username',
          ];

  static String get menuInvalidOption =>
      _isPt
          ? 'Opção inválida. Toque em uma das opções acima.'
          : 'Invalid option. Tap one of the options above.';

  static String get menuBackLabel =>
      _isPt ? '↩️ Voltar ao menu' : '↩️ Back to menu';

  // ------------------------------------------------------------------
  // Assistente com IA (assinantes)
  // ------------------------------------------------------------------
  static String get aiFallback =>
      _isPt
          ? 'Não consegui entender agora 😕 Escolha uma das opções abaixo.'
          : "I couldn't understand that right now 😕 Pick one of the options below.";

  /// Opção "Relatórios" do menu principal (só no modo IA) — valor `'5'`.
  static String get reportsOptionLabel =>
      _isPt ? '📊 Relatórios' : '📊 Reports';

  /// Opção "Encontrar orçamentos" do menu (só no modo IA) — valor `'6'`.
  static String get findBudgetOptionLabel =>
      _isPt ? '🔍 Encontrar orçamentos' : '🔍 Find budgets';

  /// Opção "Ir no cliente" do menu (só no modo IA) — valor `'8'`.
  static String get goToClientOptionLabel =>
      _isPt ? '📍 Ir no cliente' : '📍 Go to client';

  static String get goToClientPrompt =>
      _isPt
          ? 'Selecione o orçamento do cliente que você quer visitar 🚗'
          : "Select the budget of the client you want to visit 🚗";

  static String goToClientAddress(String name, String address) =>
      _isPt
          ? '📍 Endereço de $name:\n$address'
          : "📍 $name's address:\n$address";

  static String goToClientNoAddress(String name) =>
      _isPt
          ? '⚠️ O orçamento de $name não tem endereço cadastrado.'
          : "⚠️ $name's budget has no address registered.";

  static String get goToClientOpenMapLabel =>
      _isPt ? '🗺️ Abrir no mapa' : '🗺️ Open in maps';

  static String get goToClientSelectAnotherLabel =>
      _isPt ? 'Selecionar outro orçamento' : 'Select another budget';

  static String get goToClientMapErrorTitle => _isPt ? 'Erro!' : 'Error!';

  static String get goToClientMapErrorMessage =>
      _isPt
          ? 'Nenhum app de mapa conseguiu abrir o endereço.'
          : 'No map app could open the address.';

  static String get goToClientChooseMap => _isPt ? 'Abrir com' : 'Open with';

  static String get goToClientCancel => _isPt ? 'Cancelar' : 'Cancel';

  static String get findBudgetPrompt =>
      _isPt
          ? 'De qual cliente você quer encontrar o orçamento?'
          : "Which client's budget do you want to find?";

  static String findBudgetSelect(String name) =>
      _isPt ? 'Selecione o orçamento de $name' : 'Select the budget for $name';

  static String get findBudgetReopenQuestion =>
      _isPt
          ? 'Deseja abrir o orçamento novamente?'
          : 'Do you want to open the budget again?';

  static String get findBudgetReopenLabel =>
      _isPt ? 'Abrir novamente' : 'Open again';

  static String get reportsPrompt =>
      _isPt
          ? '📊 Qual relatório você quer ver? Escreva sua pergunta com suas palavras.'
          : '📊 Which report do you want to see? Write your question in your own words.';

  static String get reportsExample =>
      _isPt
          ? 'Exemplos:\n'
              '• Quantos orçamentos aprovei este mês?\n'
              '• Quanto recebi esta semana?'
          : 'Examples:\n'
              '• How many budgets did I approve this month?\n'
              '• How much did I receive this week?';

  static String get aiUnavailable =>
      _isPt
          ? 'O assistente inteligente está indisponível no momento 😕 Segui no modo padrão: escolha uma das opções abaixo.'
          : 'The smart assistant is unavailable right now 😕 Switched to standard mode: pick one of the options below.';

  static String get aiTyping => _isPt ? 'digitando…' : 'typing…';

  static String get aiDailyLimit =>
      _isPt
          ? 'Você atingiu o limite de mensagens com o assistente por hoje. Use as opções do menu ou volte amanhã. 🙂'
          : "You've reached today's assistant message limit. Use the menu options or come back tomorrow. 🙂";

  static String get aiConfirmLabel => _isPt ? 'Confirmar' : 'Confirm';

  static String get aiCancelLabel => _isPt ? 'Cancelar' : 'Cancel';

  static String get aiActionCancelled =>
      _isPt
          ? 'Ok, cancelei. Nada foi alterado.'
          : 'Ok, cancelled. Nothing was changed.';

  static String get aiActionFailed =>
      _isPt
          ? 'Não consegui concluir a ação. Tente de novo.'
          : "I couldn't complete the action. Please try again.";

  static String aiReceiptPreview({
    required String client,
    required String description,
    String? amount,
    String? method,
  }) =>
      _isPt
          ? 'Criar recibo no orçamento de $client?\nDescrição: $description'
              '${amount == null ? '' : '\nValor recebido: $amount${method == null ? '' : ' ($method)'}'}'
          : 'Create a receipt on $client\'s budget?\nDescription: $description'
              '${amount == null ? '' : '\nAmount received: $amount${method == null ? '' : ' ($method)'}'}';

  static String aiReceiptCreated(String client) =>
      _isPt
          ? 'Recibo criado no orçamento de $client ✅'
          : 'Receipt created on $client\'s budget ✅';

  static String aiStatusPreview(String client, String status) =>
      _isPt
          ? 'Alterar o status do orçamento de $client para ${budgetStatusLabel(status)}?'
          : 'Change $client\'s budget status to ${budgetStatusLabel(status)}?';

  static String aiStatusUpdated(String client, String status) =>
      _isPt
          ? 'Orçamento de $client agora está ${budgetStatusLabel(status)} ✅'
          : '$client\'s budget is now ${budgetStatusLabel(status)} ✅';

  /// Label do status persistido (o valor gravado nunca é traduzido).
  static String budgetStatusLabel(String status) => switch (status) {
    'APROVADO' => _isPt ? 'Aprovado' : 'Approved',
    'REPROVADO' => _isPt ? 'Reprovado' : 'Rejected',
    'FINALIZADO' => _isPt ? 'Finalizado' : 'Finished',
    _ => _isPt ? 'Pendente' : 'Pending',
  };

  static String get aiSelectReceiptBudget =>
      _isPt
          ? 'Selecione o orçamento que deseja criar o recibo'
          : 'Select the budget you want to create the receipt for';

  static String get aiSelectDuplicateBudget =>
      _isPt
          ? 'Selecione o orçamento que deseja duplicar'
          : 'Select the budget you want to duplicate';

  static String get aiSelectCommentBudget =>
      _isPt
          ? 'Selecione o orçamento que deseja comentar'
          : 'Select the budget you want to comment on';

  static String aiBudgetCommentsSaved(String client) =>
      _isPt
          ? 'Comentários do orçamento de $client atualizados ✅'
          : '$client\'s budget comments updated ✅';

  static String get aiBudgetCommentsSkipped =>
      _isPt
          ? 'Tudo bem, nenhum comentário adicionado.'
          : 'Alright, no comments added.';

  static String aiBudgetDuplicated(String client) =>
      _isPt
          ? 'Orçamento de $client duplicado ✅'
          : '$client\'s budget duplicated ✅';

  static String get aiBudgetDuplicateFailed =>
      _isPt
          ? 'Não consegui duplicar o orçamento. Tente novamente.'
          : 'Could not duplicate the budget. Please try again.';

  static String get aiSelectBudgetLabel =>
      _isPt ? 'Selecionar orçamento' : 'Select budget';

  static String get aiBudgetListTitle => _isPt ? 'Orçamentos' : 'Budgets';

  static String aiBudgetListFooter(int count, String total) =>
      _isPt ? '$count orçamento(s) · $total' : '$count budget(s) · $total';

  static String aiSummaryTitle(String month) =>
      _isPt ? 'Resumo de $month' : '$month summary';

  static String get aiSummaryTotal => _isPt ? 'Total gerado' : 'Total created';

  static String aiReceiptsReportTitle(String from, String to) =>
      _isPt ? 'Recibos de $from a $to' : 'Receipts from $from to $to';

  static String get aiReceiptsCountLabel => _isPt ? 'Recibos' : 'Receipts';

  static String get aiReceiptsIssuedLabel => _isPt ? 'Emitido' : 'Issued';

  static String get aiReceiptsPaidLabel => _isPt ? 'Recebido' : 'Received';

  static String aiReceiptsPrevious(int count, String paid) =>
      _isPt
          ? 'Período anterior: $count recibo(s) · $paid recebido'
          : 'Previous period: $count receipt(s) · $paid received';

  static String get aiReceiptsTopLabel =>
      _isPt ? 'Orçamentos com mais recebido' : 'Top budgets by received';

  static String get aiOpenBudget => _isPt ? 'Abrir' : 'Open';

  static String get aiShareLinkLabel =>
      _isPt ? 'Compartilhar link' : 'Share link';

  static String aiSystemPrompt({
    required String today,
    required String userName,
  }) => '''
Você é o assistente do OFLite, app de orçamentos e recibos para prestadores de serviço.
Hoje é $today (formato yyyy-MM-dd). Usuário: ${userName.isEmpty ? 'não informado' : userName}.

Domínio:
- Orçamento: cliente, telefone, endereço, itens, observações, valor total e status.
- Status (use EXATAMENTE): PENDENTE, APROVADO, REPROVADO, FINALIZADO.
- Recibo: sempre pertence a UM orçamento; tem descrição e pagamentos (valor e forma). "Recebido" = soma dos pagamentos.
- Relatório de recibos de um período (semana, mês, intervalo, de todos os orçamentos) → get_receipts_report. Semana = segunda a domingo. Recibos de UM orçamento → list_receipts.
- "Esse mês" = mês de hoje. "Mês passado" = mês anterior. Datas das ferramentas em yyyy-MM-dd; mês em yyyy-MM.

Regras:
1. Responda no idioma do usuário (${_isPt ? 'português do Brasil' : 'English'} por padrão), em no máximo 2 frases curtas. Texto puro, sem markdown.
2. Use SEMPRE as ferramentas para obter dados. Nunca invente números, nomes ou ids.
3. Nunca some nem calcule valores: repita os totais formatados que as ferramentas devolvem.
4. A lista/card do resultado já aparece na tela: não repita os itens, só comente em 1 frase.
5. Para agir sobre um orçamento você precisa do budget_id: obtenha com list_budgets (use client_name). Se houver mais de um, pergunte qual (cite cliente, data e valor).
6. Ações que gravam dados (create_receipt, update_budget_status) mostram um botão de confirmação ao usuário: chame a ferramenta direto, sem pedir confirmação em texto.
7. Para criar orçamento, cadastrar produtos, editar o PDF/logo ou trocar o nome de usuário, chame start_flow sem perguntar antes.
8. Se o usuário quer criar ou ver recibos e ainda não escolheu o orçamento, chame list_budgets com purpose "receipts" (abre um modal para o usuário escolher; não pergunte qual orçamento em texto). Para duplicar/clonar um orçamento, chame list_budgets com purpose "duplicate" do mesmo jeito. Para adicionar/editar comentários ou observações de um orçamento, chame list_budgets com purpose "comments" do mesmo jeito (não pergunte o cliente em texto). Para ir no/até o cliente, ver o endereço do cliente, rota, GPS ou abrir no mapa, chame list_budgets com purpose "go_to_client" do mesmo jeito (o app mostra o endereço e abre o mapa; nunca diga que não consegue).
9. Se faltar dado obrigatório, pergunte UMA coisa por vez. Fora do escopo do app, diga educadamente o que você sabe fazer.
10. "Anexar", "adicionar", "salvar", "juntar", "enviar" ou "guardar" nota fiscal/comprovante (de pagamento ou de compra) num orçamento são a MESMA coisa e o app suporta: diga em 1 frase para tocar no "+" ao lado do campo de mensagem e escolher a foto, a câmera ou o PDF; depois o app pergunta o orçamento. Nunca diga que não suporta notas fiscais ou comprovantes.
11. Se uma ferramenta devolver error, diga em 1 frase que não conseguiu e sugira tentar de novo. NUNCA responda com dados de outra ferramenta no lugar (ex.: resumo de orçamentos quando pediram recibos).
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
          ? const ['📋 Ver lista de produtos', '➕ Adicionar um novo produto']
          : const ['📋 View product list', '➕ Add new product'];

  // ------------------------------------------------------------------
  // Comentários (biblioteca — só modo IA/assinantes)
  // ------------------------------------------------------------------
  /// Opção do menu principal (só no modo IA) — valor `'7'`.
  static String get commentLibraryOptionLabel =>
      _isPt ? '💬 Cadastrar comentários' : '💬 Saved comments';

  static String get commentLibraryMenuQuestion =>
      _isPt
          ? 'Beleza! O que você quer fazer com seus comentários?'
          : 'Sure! What do you want to do with your comments?';

  static List<String> get commentLibraryMenuOptionLabels =>
      _isPt
          ? const ['📋 Ver meus comentários', '➕ Adicionar um novo comentário']
          : const ['📋 View my comments', '➕ Add a new comment'];

  static String commentLibraryCreated(String name) =>
      _isPt
          ? 'Comentário "$name" salvo com sucesso! 🎉'
          : 'Comment "$name" saved successfully! 🎉';

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
            'CNPJ / CPF',
            'Endereço',
            'Logo',
            'Modelo de PDF',
          ]
          : const [
            'Company name',
            'Phone',
            'Email',
            'CNPJ / CPF',
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
      _isPt
          ? 'Digite o CNPJ ou CPF da empresa:'
          : 'Enter the company CNPJ or CPF:';

  static String pdfEditCurrentDocument(String value) =>
      _isPt
          ? 'O CNPJ / CPF atual é "$value".'
          : 'The current CNPJ / CPF is "$value".';

  static String get documentFormHint => _isPt ? 'CNPJ ou CPF' : 'CNPJ or CPF';

  static String get documentFormSave => _isPt ? 'Salvar' : 'Save';

  static String get documentFormCancel => _isPt ? 'Voltar' : 'Back';

  static String documentError(DocumentValidationError error) {
    switch (error) {
      case DocumentValidationError.empty:
        return _isPt
            ? 'O campo CPF ou CNPJ é obrigatório.'
            : 'CPF or CNPJ is required.';
      case DocumentValidationError.invalidCpf:
        return _isPt ? 'CPF inválido.' : 'Invalid CPF.';
      case DocumentValidationError.invalidCnpj:
        return _isPt ? 'CNPJ inválido.' : 'Invalid CNPJ.';
      case DocumentValidationError.invalidLength:
        return _isPt
            ? 'Digite um CPF ou CNPJ válido.'
            : 'Enter a valid CPF or CNPJ.';
    }
  }

  static String get pdfEditInvalidPhone =>
      _isPt
          ? 'Telefone inválido. Informe apenas números com DDD.'
          : 'Invalid phone. Enter only numbers with area code.';

  static String get pdfEditInvalidEmail =>
      _isPt
          ? 'Email inválido. Informe um email válido.'
          : 'Invalid email. Enter a valid email.';

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

  static String pdfEditSuccessDocument(DocumentType type) {
    final label = type == DocumentType.cpf ? 'CPF' : 'CNPJ';
    return _isPt
        ? '$label atualizado com sucesso:'
        : '$label successfully updated:';
  }

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

  static String get budgetCreatedSuccess =>
      _isPt
          ? 'Orçamento criado com sucesso! 👍🎉'
          : 'Budget created successfully! 👍🎉';

  static String get shareLinkLabel =>
      _isPt ? 'Compartilhar link' : 'Share link';

  static String get generatePdfLabel => _isPt ? 'Gerar PDF' : 'Generate PDF';

  static String get pdfUnavailable =>
      _isPt
          ? 'Não foi possível gerar o PDF. Tente novamente.'
          : 'Could not generate the PDF. Please try again.';

  // ------------------------------------------------------------------
  // Textos que estavam fixos na View/ViewModel/componentes (fase 1 da §16).
  // Ainda só em pt, exatamente como eram exibidos — traduzir é outra fase.
  // ------------------------------------------------------------------

  static String get assistantTitle => 'Assistente';

  static String get restartConversation => 'Reiniciar conversa';

  static String get shareError => 'Erro ao compartilhar';

  static String get editLogoTitle => 'Editar Logo';

  static String get editingMessageTitle => 'Editando mensagem';

  static String get editMessageHint => 'Edite a mensagem...';

  static String get typeMessageHint => 'Digite uma mensagem...';

  static String get cepField => 'CEP';

  static String get neighborhoodField => 'Bairro (opcional)';

  static String get confirmAddressButton => 'Confirmar endereço';

  static String get holdToEdit => 'Toque e segure para editar';

  static String get openLabel => 'Abrir';

  static String get pickContactLabel => 'Escolher contato';

  static String get editSelection => 'Editar seleção';

  static String get changeLogoLabel => 'Alterar logo';

  static String pdfSizeLabel(Object kb) => 'PDF · $kb KB';

  static String get invalidPhone =>
      'Telefone inválido. Informe apenas números com DDD. Ex: (11) 99999-9999 ou 11999999999.';

  static String processingError(Object e) => 'Erro ao processar: $e';

  static String confirmClientData(String name, String phone) =>
      'Confirme os dados do cliente:\n'
      'Nome: $name\n'
      'Telefone: ${phone.isEmpty ? '—' : phone}';

  static String get createBudgetFailed =>
      'Ops, não consegui criar o orçamento. Tente novamente.';

  static String get selectProductsLabel => 'Selecionar produtos';

  static String get selectItemsToContinue =>
      _isPt
          ? 'Para seguir preciso que você selecione os itens do orçamento'
          : 'To continue I need you to select the budget items';

  static String get invalidCep => 'CEP inválido. Digite 8 números.';

  static String foundAddress(
    String street,
    String? neighborhood,
    String city,
  ) =>
      'Encontrei o endereço:\n'
      '$street\n'
      '${neighborhood != null ? '$neighborhood\n' : ''}'
      '$city';

  static String fetchPdfDataError(Object e) =>
      'Erro ao buscar dados do PDF: $e';

  static String saveAddressError(Object e) => 'Erro ao salvar endereço: $e';

  static String get addressSaved => 'Endereço cadastrado com sucesso.';

  static String get streetAndCityRequired =>
      'Informe pelo menos a rua e a cidade.';

  static String get noBudgetItems => 'Nenhum item no orçamento.';

  static String get budgetItemsTitle => 'Itens do orçamento:';

  static String budgetItemsTotal(String total) => 'Total: R\$ $total';

  static String get askAddComments =>
      'Deseja adicionar algum comentário ou observação ao orçamento?';

  static String get finalizeBudgetFailed =>
      'Erro ao finalizar o orçamento. Tente novamente.';

  static String get budgetNotAvailableToShare =>
      'Orçamento não disponível para compartilhar';

  static String get shareLinkFailed =>
      'Não foi possível gerar o link. Verifique sua conexão.';

  static String get shareSubject => 'Orçamento';

  static String get productCreated => 'Produto criado com sucesso! 🎉';

  static String productCreatedDetails(
    String desc,
    String price,
    String category,
  ) =>
      'Produto criado com sucesso! 🎉\n\n'
      'Descrição: $desc\n'
      'Preço: R\$ $price\n'
      'Categoria: $category';

  static String get commentsUpdated =>
      'Comentários atualizados com sucesso. Deseja editar '
      'novamente ou finalizar o orçamento?';
}
