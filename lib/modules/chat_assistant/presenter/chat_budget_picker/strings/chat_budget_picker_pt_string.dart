import 'package:flutter/widgets.dart';

/// Textos do modal de seleção de orçamento do chat.
class ChatBudgetPickerStrings {
  const ChatBudgetPickerStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  static String get title =>
      _isPt ? 'Selecione o orçamento' : 'Select a budget';

  static String get searchHint =>
      _isPt ? 'Buscar cliente...' : 'Search client...';

  static String get allStatus => _isPt ? 'Todos' : 'All';

  static String get empty =>
      _isPt ? 'Nenhum orçamento encontrado' : 'No budgets found';
}
