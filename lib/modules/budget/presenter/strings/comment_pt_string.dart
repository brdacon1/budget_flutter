import 'package:flutter/widgets.dart';

/// Textos do módulo Comment internacionalizados.
class CommentStrings {
  const CommentStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get addButton => _isPt ? 'ADICIONAR' : 'ADD';

  static String get updateButton => _isPt ? 'ATUALIZAR' : 'UPDATE';

  static String get saving => _isPt ? 'Salvando...' : 'Saving...';

  static String get title => _isPt ? 'Comentário' : 'Comment';

  static String get hint =>
      _isPt ? 'Escreva o comentário...' : 'Write the comment...';

  static String get successTitle => _isPt ? 'Feito!' : 'Done!';

  static String get successAddMessage =>
      _isPt
          ? 'Comentário adicionado com sucesso!'
          : 'Comment added successfully!';

  static String get successUpdateMessage =>
      _isPt
          ? 'Comentário atualizado com sucesso!'
          : 'Comment updated successfully!';

  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';

  static String get errorAddMessage =>
      _isPt
          ? 'Não foi possível adicionar o comentário'
          : 'Could not add the comment';

  static String get errorUpdateMessage =>
      _isPt
          ? 'Não foi possível atualizar o comentário'
          : 'Could not update the comment';

  static String get deleteLabel => _isPt ? 'Excluir' : 'Delete';

  static String get editLabel => _isPt ? 'Editar' : 'Edit';

  // --- Lista: seleção e remoção em massa ---
  static String get screenTitle => _isPt ? 'Comentários' : 'Comments';
  static String get screenSubtitle =>
      _isPt ? 'Comentários do orçamento' : 'Budget comments';
  static String get newComment => _isPt ? 'Novo comentário' : 'New comment';
  static String get emptyList =>
      _isPt ? 'O orçamento não possui comentários' : 'This budget has no comments';
  static String get loadError =>
      _isPt
          ? 'Não foi possível carregar os comentários'
          : 'Could not load the comments';
  static String dateLabel(String date) => _isPt ? 'Data: $date' : 'Date: $date';
  static String removeCount(int n) => _isPt ? 'Remover ($n)' : 'Remove ($n)';
  static String selectedCount(int n) =>
      _isPt ? '$n ${n == 1 ? 'selecionado' : 'selecionados'}' : '$n selected';
  static String get selectAll => _isPt ? 'Selecionar todos' : 'Select all';
  static String get clearAll => _isPt ? 'Limpar' : 'Clear';
  static String get cancelSelection => _isPt ? 'Cancelar' : 'Cancel';
  static String removeTitle(int n) =>
      _isPt
          ? 'Remover $n ${n == 1 ? 'comentário' : 'comentários'}?'
          : 'Remove $n ${n == 1 ? 'comment' : 'comments'}?';
  static String get removeMessage =>
      _isPt ? 'Essa ação não pode ser desfeita.' : 'This cannot be undone.';
  static String get removeSuccess =>
      _isPt ? 'Comentários removidos.' : 'Comments removed.';
  static String get removeError =>
      _isPt
          ? 'Não foi possível remover. Verifique sua conexão e tente novamente.'
          : 'Could not remove. Check your connection and try again.';

  // --- Modal de detalhe ---
  static String get cancelLabel => _isPt ? 'Cancelar' : 'Cancel';
  static String get saveLabel => _isPt ? 'Salvar' : 'Save';
  static String get emptyTextError =>
      _isPt ? 'Escreva o comentário.' : 'Write the comment.';
}
