/// Contrato para geração de link público compartilhável de orçamento.
abstract class ShareLinkRepository {
  /// Gera a URL compartilhável para o orçamento de [enderecoNumero],
  /// embutindo um Firebase ID Token fresco do usuário atual.
  ///
  /// Retorna `null` se não houver usuário autenticado.
  Future<String?> buildShareUrl({required String enderecoNumero});
}
