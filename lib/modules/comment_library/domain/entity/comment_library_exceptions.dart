/// Texto do comentário vazio.
class CommentTextEmptyException implements Exception {
  const CommentTextEmptyException();
}

/// Texto acima de [maxLength] caracteres.
class CommentTextTooLongException implements Exception {
  const CommentTextTooLongException(this.maxLength);
  final int maxLength;
}

/// A IA devolveu um texto que não pode substituir o original
/// (vazio, longo demais ou perdeu valores/prazos).
class CommentImproveInvalidException implements Exception {
  const CommentImproveInvalidException();
}

/// Salvou na biblioteca, mas não conseguiu adicionar ao orçamento.
class CommentSavedButNotLinkedException implements Exception {
  const CommentSavedButNotLinkedException(this.commentId);
  final String commentId;
}
