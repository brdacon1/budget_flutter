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

  static String get finalizeAndGenerateLink => _isPt
      ? 'Finalizar e gerar link'
      : 'Finalize and generate link';

  static String get editingMessage =>
      _isPt ? 'Editando mensagem' : 'Editing message';

  static String get streetField => _isPt ? 'Rua' : 'Street';

  static String get numberField => _isPt ? 'Número' : 'Number';

  static String get cityField => _isPt ? 'Cidade' : 'City';

  static String get cancelAndProceed => _isPt
      ? 'Cancelar e seguir com a geração do orçamento'
      : 'Cancel and proceed with budget generation';

  static String get clientFallback => _isPt ? 'Cliente' : 'Client';

  static String get budgetNotAvailable => _isPt
      ? 'Orçamento não disponível para compartilhar'
      : 'Budget not available for sharing';

  static String get tapAndHoldToEdit => _isPt
      ? 'Toque e segure para editar'
      : 'Tap and hold to edit';

  static String get contactPickerHint => _isPt
      ? 'Selecione nos contatos ou escreva no campo abaixo e me envie'
      : 'Select from contacts or type in the field below and send me';

  // ------------------------------------------------------------------
  // Menu principal do chat (estilo bot WhatsApp)
  // ------------------------------------------------------------------
  static String get mainMenuQuestion => _isPt
      ? 'O que eu posso fazer por você?'
      : 'What can I do for you?';

  static String get mainMenuOptions => _isPt
      ? '1. Criar orçamentos\n'
        '2. Lista de preço\n'
        '3. Editar PDF\n'
        '4. Trocar nome de usuário'
      : '1. Create budget\n'
        '2. Price list\n'
        '3. Edit PDF\n'
        '4. Change username';

  static String get menuInvalidOption => _isPt
      ? 'Opção inválida. Envie o número correspondente.'
      : 'Invalid option. Send the corresponding number.';

  static String get menuBackOption => _isPt
      ? '0. Voltar ao menu'
      : '0. Back to menu';

  static String get budgetTransition => _isPt
      ? 'Vamos lá! 💪'
      : 'Let\'s go! 💪';

  // ------------------------------------------------------------------
  // Lista de preço
  // ------------------------------------------------------------------
  static String get priceListMenuQuestion => _isPt
      ? 'Legal, o que você quer fazer?'
      : 'Great, what do you want to do?';

  static String get priceListMenuOptions => _isPt
      ? '1. Ver lista de produtos\n2. Adicionar um novo produto'
      : '1. View product list\n2. Add new product';

  // ------------------------------------------------------------------
  // Editar PDF
  // ------------------------------------------------------------------
  static String get pdfEditMenuQuestion => _isPt
      ? 'Qual informação do PDF você quer mudar?'
      : 'Which PDF information do you want to change?';

  static String get pdfEditMenuOptions => _isPt
      ? '1. Nome da empresa\n'
        '2. Telefone\n'
        '3. Email\n'
        '4. CNPJ\n'
        '5. Endereço\n'
        '6. Logo'
      : '1. Company name\n'
        '2. Phone\n'
        '3. Email\n'
        '4. CNPJ\n'
        '5. Address\n'
        '6. Logo';

  static String get pdfEditAskName => _isPt
      ? 'Digite o novo nome da empresa:'
      : 'Enter the new company name:';

  static String get pdfEditAskPhone => _isPt
      ? 'Digite o novo telefone da empresa (com DDD):'
      : 'Enter the new company phone (with area code):';

  static String get pdfEditAskEmail => _isPt
      ? 'Digite o novo email:'
      : 'Enter the new email:';

  static String get pdfEditAskCnpj => _isPt
      ? 'Digite o novo CNPJ:'
      : 'Enter the new CNPJ:';

  static String get pdfEditInvalidPhone => _isPt
      ? 'Telefone inválido. Informe apenas números com DDD.'
      : 'Invalid phone. Enter only numbers with area code.';

  static String get pdfEditInvalidEmail => _isPt
      ? 'Email inválido. Informe um email válido.'
      : 'Invalid email. Enter a valid email.';

  static String get pdfEditInvalidCnpj => _isPt
      ? 'CNPJ inválido. Informe 14 números.'
      : 'Invalid CNPJ. Enter 14 numbers.';

  static String get pdfEditSuccessName => _isPt
      ? 'Nome da empresa atualizado com sucesso para:'
      : 'Company name successfully updated to:';

  static String get pdfEditSuccessPhone => _isPt
      ? 'Telefone atualizado com sucesso:'
      : 'Phone successfully updated:';

  static String get pdfEditSuccessEmail => _isPt
      ? 'Email atualizado com sucesso:'
      : 'Email successfully updated:';

  static String get pdfEditSuccessCnpj => _isPt
      ? 'CNPJ atualizado com sucesso:'
      : 'CNPJ successfully updated:';

  static String get pdfEditSuccessAddress => _isPt
      ? 'Endereço atualizado com sucesso.'
      : 'Address successfully updated.';

  static String get pdfEditAskHasCep => _isPt
      ? 'Vamos atualizar o endereço da sua empresa. Você tem o CEP?'
      : 'Let\'s update your company address. Do you have the ZIP code?';

  // ------------------------------------------------------------------
  // Logo submenu
  // ------------------------------------------------------------------
  static String get logoMenuQuestion => _isPt
      ? 'O que você quer fazer com a logo?'
      : 'What do you want to do with the logo?';

  static String get logoMenuOptions => _isPt
      ? '1. Ver logo da empresa\n2. Inserir/Alterar logo'
      : '1. View company logo\n2. Insert/Change logo';

  // ------------------------------------------------------------------
  // Trocar nome de usuário
  // ------------------------------------------------------------------
  static String get changeUsernameInstructions => _isPt
      ? 'Vou abrir o modal para você alterar o nome de usuário.'
      : 'I will open the modal so you can change your username.';

  static String get changeUsernameMenuOptions => _isPt
      ? '1. Alterar nome de usuário'
      : '1. Chance user name';

  static String get changeUsernameSuccess => _isPt
      ? 'Nome de usuário atualizado com sucesso para:'
      : 'Username successfully updated to:';

  static String get changeUsernameCancelled => _isPt
      ? 'Ok, deixei como está.'
      : 'Okay, I left it as is.';

  static String get changeUsernameNotChanged => _isPt
      ? 'Você não alterou o nome de usuário.'
      : 'You did not change the username.';

  static String get changeUsernameRetryQuestion => _isPt
      ? '1. Trocar novamente\n2. Voltar ao menu principal'
      : '1. Change again\n2. Back to main menu';
}
