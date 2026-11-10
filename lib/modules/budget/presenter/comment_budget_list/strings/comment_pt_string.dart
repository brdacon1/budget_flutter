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

  static String get successAddMessage => _isPt
      ? 'Comentário adicionado com sucesso!'
      : 'Comment added successfully!';

  static String get successUpdateMessage => _isPt
      ? 'Comentário atualizado com sucesso!'
      : 'Comment updated successfully!';

  static String get errorTitle => _isPt ? 'Erro!' : 'Error!';

  static String get errorAddMessage => _isPt
      ? 'Não foi possível adicionar o comentário'
      : 'Could not add the comment';

  static String get errorUpdateMessage => _isPt
      ? 'Não foi possível atualizar o comentário'
      : 'Could not update the comment';

  static String get deleteLabel => _isPt ? 'Excluir' : 'Delete';

  static String get editLabel => _isPt ? 'Editar' : 'Edit';
}
