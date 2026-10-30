import 'package:flutter/widgets.dart';

/// Textos do módulo ChatBudget internacionalizados.
class ChatBudgetStrings {
  const ChatBudgetStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get assistantName =>
      _isPt ? 'Assistente' : 'Assistant';

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

  static String get streetField =>
      _isPt ? 'Rua e número' : 'Street and number';

  static String get cityField => _isPt ? 'Cidade' : 'City';

  static String get clientFallback =>
      _isPt ? 'Cliente' : 'Client';

  static String get budgetNotAvailable => _isPt
      ? 'Orçamento não disponível para compartilhar'
      : 'Budget not available for sharing';

  static String get tapAndHoldToEdit => _isPt
      ? 'Toque e segure para editar'
      : 'Tap and hold to edit';

  static String get contactPickerHint => _isPt
      ? 'Selecione nos contatos ou escreva no campo abaixo e me envie'
      : 'Select from contacts or type in the field below and send me';
}
