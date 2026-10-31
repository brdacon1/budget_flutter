/// Entidade do script configurável do bot no Firestore.
///
/// Todas as mensagens que o bot exibe podem ser alteradas
/// editando o documento `CONFIG/CHAT_SCRIPT/DEFAULT`.
class ChatScriptEntity {
  final String askClientName;
  final String askPhone;
  final String askAddress;
  final String askHasCep;
  final String askCep;
  final String cepNotFound;
  final String askStreetFallback;
  final String askProducts;
  final String finalMessage;
  final String shareLabel;

  const ChatScriptEntity({
    required this.askClientName,
    required this.askPhone,
    required this.askAddress,
    required this.askHasCep,
    required this.askCep,
    required this.cepNotFound,
    required this.askStreetFallback,
    required this.askProducts,
    required this.finalMessage,
    required this.shareLabel,
  });

  /// Fallback quando o documento ainda não foi criado no Firestore.
  static const ChatScriptEntity fallback = ChatScriptEntity(
    askClientName: 'Para quem você quer criar um orçamento?',
    askPhone: 'Qual o telefone do cliente?',
    askAddress: 'Você quer incluir o endereço do cliente?',
    askHasCep: 'Você tem o CEP do endereço do cliente?',
    askCep: 'Qual o CEP?',
    cepNotFound: 'Não encontrei esse CEP. Vou pedir os dados manualmente.',
    askStreetFallback: 'Informe a rua, número e cidade:',
    askProducts: 'Selecione os produtos do orçamento:',
    finalMessage: 'Orçamento gerado com sucesso!',
    shareLabel: 'Compartilhar link',
  );
}
