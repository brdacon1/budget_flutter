library oflite.globals;

String? id;
String? user;
String? email;
String? password;
String? name;
String? phone;
String? purchaseToken;
bool?   autoRenewing = false;
String? idPay;
String? productId;
bool? googleAuth = false;

/// Lista de tokens FCM push do dono (um por dispositivo). Espelha
/// `InfoUser.TOKENS` para que o restante do app acesse sem depender da
/// instância de `InfoUser`. Preenchida em `_getUserInfo`.
List<String> tokens = const [];
