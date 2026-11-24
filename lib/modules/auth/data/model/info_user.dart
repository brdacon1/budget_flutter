class InfoUser {
  String? id;
  String? user;
  String? email;
  String? password;
  String? name;
  String? phone;
  String? purchaseToken;
  bool? autoRenewing = false;
  String? idPay;
  String? productId;
  bool? googleAuth = false;

  /// Início do teste grátis (horário do servidor). `null` = ainda não
  /// sincronizado (offline/conta antiga): o acesso nunca é bloqueado.
  DateTime? trialStartedAt;

  /// Diferença servidor − aparelho, medida no último sync. Impede burlar o
  /// trial mudando a data do celular.
  Duration serverClockOffset = Duration.zero;

  /// Lista de tokens FCM push do dono (um por dispositivo onde ele fez
  /// login). Preenchida em `_getUserInfo` lendo
  /// `EMPRESAS/{uid}/USERS/{uid}/FCM`. A Cloud Function lê essa
  /// mesma lista para enviar o push de aprovação/reprovação a TODOS os
  /// devices do dono — assim a notificação chega mesmo com o app fechado,
  /// não importa em quantos aparelhos a pessoa esteja conectada.
  List<String> tokens = const [];
}
