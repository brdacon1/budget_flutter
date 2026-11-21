/// Contrato para geração de link público compartilhável de orçamento.
abstract class ShareLinkRepository {
  /// Gera a URL compartilhável para o orçamento de [enderecoNumero],
  /// no formato curto `{host}/o/{code}` (código com escopo de um orçamento).
  ///
  /// Retorna `null` se não houver usuário autenticado ou a geração falhar.
  Future<String?> buildShareUrl({required String enderecoNumero});
}
