/// Entidade do script configurável do bot no Firestore.
///
/// Todas as mensagens que o bot exibe podem ser alteradas
/// editando o documento `CONFIG/CHAT_SCRIPT/DEFAULT`.
class ChatScriptEntity {
  final String welcomeMessage;
  final String askClientName;
  final String askPhone;
  final String askAddress;
  final String askCep;
  final String askStreetFallback;
  final String askProducts;
  final String finalMessage;
  final String shareLabel;

  const ChatScriptEntity({
    required this.welcomeMessage,
    required this.askClientName,
    required this.askPhone,
    required this.askAddress,
    required this.askCep,
    required this.askStreetFallback,
    required this.askProducts,
    required this.finalMessage,
    required this.shareLabel,
  });

  /// Fallback quando o documento ainda não foi criado no Firestore.
  static const ChatScriptEntity fallback = ChatScriptEntity(
    welcomeMessage:
        'Olá! Sou seu assistente de orçamentos. Para quem você quer criar um orçamento?',
    askClientName: 'Para quem você quer criar um orçamento?',
    askPhone: 'Qual o telefone do cliente?',
    askAddress: 'Quer cadastrar o endereço do cliente?',
    askCep: 'Qual o CEP?',
    askStreetFallback: 'Informe a rua, número e cidade:',
    askProducts: 'Selecione os produtos do orçamento:',
    finalMessage: 'Orçamento gerado com sucesso!',
    shareLabel: 'Compartilhar link',
  );
}
