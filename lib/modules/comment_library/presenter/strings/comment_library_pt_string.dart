import 'package:flutter/widgets.dart';

/// Textos do módulo de biblioteca de comentários (pt / en fallback).
class CommentLibraryStrings {
  const CommentLibraryStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  // --- Lista ---
  static String get listTitle => _isPt ? 'Comentários' : 'Comments';
  static String get searchHint => _isPt ? 'Buscar comentário' : 'Search comment';
  static String get newComment => _isPt ? 'Novo comentário' : 'New comment';
  static String get emptyList =>
      _isPt
          ? 'Nenhum comentário salvo.\nToque em "Novo comentário" para criar.'
          : 'No saved comments.\nTap "New comment" to create one.';
  static String removeSelected(int n) => _isPt ? 'Remover ($n)' : 'Remove ($n)';
  static String selectedCount(int n) =>
      _isPt
          ? '$n ${n == 1 ? 'selecionado' : 'selecionados'}'
          : '$n selected';
  static String get selectAll => _isPt ? 'Selecionar todos' : 'Select all';
  static String get clearSelection => _isPt ? 'Limpar' : 'Clear';
  static String get cancelSelection => _isPt ? 'Cancelar' : 'Cancel';
  static String confirmRemoveTitle(int n) =>
      _isPt
          ? 'Remover $n ${n == 1 ? 'comentário' : 'comentários'}?'
          : 'Remove $n ${n == 1 ? 'comment' : 'comments'}?';
  static String get confirmRemoveMessage =>
      _isPt
          ? 'Orçamentos que já usam esses comentários não serão alterados.'
          : 'Budgets that already use these comments will not change.';
  static String get deleteSuccess =>
      _isPt ? 'Comentários removidos.' : 'Comments removed.';
  static String get deleteError =>
      _isPt
          ? 'Não foi possível remover. Verifique sua conexão e tente novamente.'
          : 'Could not remove. Check your connection and try again.';
  static String get loadError =>
      _isPt
          ? 'Não foi possível carregar os comentários. Puxe para atualizar.'
          : 'Could not load comments. Pull to refresh.';

  // --- Creator ---
  static String get createTitle => _isPt ? 'Novo comentário' : 'New comment';
  static String get editTitle => _isPt ? 'Editar comentário' : 'Edit comment';
  static String get saveButton => _isPt ? 'Salvar' : 'Save';
  static String get saveChangesButton =>
      _isPt ? 'Salvar alterações' : 'Save changes';
  static String get saving => _isPt ? 'Salvando...' : 'Saving...';
  static String get nameLabel => _isPt ? 'Nome' : 'Name';
  static String get nameHint =>
      _isPt ? 'Deixe vazio para a IA sugerir' : 'Leave empty for AI to suggest';
  static String get textLabel => _isPt ? 'Comentário' : 'Comment';
  static String get textHint =>
      _isPt
          ? 'Ex.: Garantia de 90 dias para mão de obra.'
          : 'E.g.: 90-day labor warranty.';
  static String get nameByAiInfo =>
      _isPt
          ? 'O nome é criado pela IA ao salvar, a partir do assunto do texto.'
          : 'The name is created by AI on save, based on the text topic.';
  static String get improveButton =>
      _isPt ? 'Melhorar com IA' : 'Improve with AI';
  static String get improving => _isPt ? 'Melhorando...' : 'Improving...';
  static String get undoButton => _isPt ? 'Desfazer' : 'Undo';
  static String get textEmptyError =>
      _isPt ? 'Escreva o comentário.' : 'Write the comment.';
  static String textTooLongError(int max) =>
      _isPt ? 'Use no máximo $max caracteres.' : 'Use at most $max characters.';

  // --- Feedback ---
  static String get doneTitle => _isPt ? 'Pronto' : 'Done';
  static String get errorTitle => _isPt ? 'Algo deu errado' : 'Something went wrong';
  static String get warningTitle => _isPt ? 'Atenção' : 'Heads up';
  static String savedAs(String name) =>
      _isPt ? 'Comentário salvo como "$name".' : 'Comment saved as "$name".';
  static String get saveError =>
      _isPt
          ? 'Não foi possível salvar. Verifique sua conexão e tente novamente.'
          : 'Could not save. Check your connection and try again.';
  static String get savedNotLinked =>
      _isPt
          ? 'O comentário foi salvo na lista, mas não entrou no orçamento. '
              'Adicione pela lista de comentários.'
          : 'The comment was saved to the list but not added to the budget. '
              'Add it from the comment list.';
  static String get improveError =>
      _isPt
          ? 'A IA não conseguiu melhorar agora. Seu texto foi mantido.'
          : 'AI could not improve it now. Your text was kept.';
  static String get improveLimit =>
      _isPt
          ? 'Limite diário de uso da IA atingido. Tente amanhã.'
          : 'Daily AI limit reached. Try again tomorrow.';

  // --- Orçamento: escolha + modal-lista ---
  static String get optionTitle =>
      _isPt
          ? 'Como você quer inserir o comentário?'
          : 'How do you want to add the comment?';
  static String get optionCreate =>
      _isPt ? 'Criar novo comentário' : 'Create new comment';
  static String get optionSelect =>
      _isPt ? 'Selecionar da lista de comentários' : 'Select from comment list';
  static String get pickerTitle =>
      _isPt ? 'Lista de comentários' : 'Comment list';
  static String get pickerEmpty =>
      _isPt ? 'Nenhum comentário encontrado.' : 'No comments found.';
  static String pickerCount(int n) =>
      _isPt
          ? '$n ${n == 1 ? 'comentário' : 'comentários'}'
          : '$n ${n == 1 ? 'comment' : 'comments'}';
  static String get pickerSelectedLabel =>
      _isPt ? 'Selecionados' : 'Selected';
  static String get pickerAdd => _isPt ? 'Adicionar' : 'Add';
  static String get pickerAdding => _isPt ? 'Adicionando...' : 'Adding...';
  static String get addedToBudget =>
      _isPt ? 'Comentários adicionados ao orçamento.' : 'Comments added to the budget.';
  static String get addToBudgetError =>
      _isPt
          ? 'Não foi possível adicionar todos. Verifique sua conexão e tente novamente.'
          : 'Could not add them all. Check your connection and try again.';
}
