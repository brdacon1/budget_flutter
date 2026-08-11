import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_budget.dart' as budget;
import 'package:oflite/models/global_uid_user.dart' as uid;
import 'package:oflite/presentations/budget/budget_tab/budget_tab_view.dart';
import 'package:oflite/services/http_request.dart';

/// Inicializa e gerencia as notificações push (FCM) do app.
///
/// Responsabilidades:
/// - Inicializa o `flutter_local_notifications` e cria o canal Android
///   `high_importance_channel` em runtime (obrigatório no Android 8+ para que
///   o FCM consiga exibir notificações que referenciem esse canal).
/// - Configura a apresentação de notificações em foreground (iOS).
/// - Registra handlers para os **três estados** do app:
///   - foreground: `FirebaseMessaging.onMessage` → notificação local.
///   - background: o sistema exibe a notificação (`notification` payload);
///     ao tocar, `FirebaseMessaging.onMessageOpenedApp` abre o orçamento.
///   - terminated (app fechado): o sistema exibe a notificação; ao tocar,
///     `FirebaseMessaging.getInitialMessage` abre o orçamento (deep-link).
/// - Persiste o token FCM do dono em `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}`,
///   lido pela Cloud Function `onBudgetApprovalNotification` para enviar o
///   push real (necessário para notificar com o app **fechado**).
///
/// O push real é disparado por uma Cloud Function (ver `functions/index.js`)
/// que escuta a escrita em `EMPRESAS/{uid}/USERS/{uid}/NOTIFICACOES` (mesmo
/// documento gravado pelo fluxo Web quando o cliente aprova/reprova) e envia
/// uma mensagem FCM com `notification` + `data` para o token do dono.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Chave do navigator global do app (definida em `main.dart`). Usada para
  /// navegar até o orçamento quando o dono **toca no banner** da notificação
  // de aprovação/reprovação vinda do fluxo Web.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Id do orçamento pendente de abertura: preenchido quando o toque na
  // notificação chega antes do navigator/dono estarem prontos (ex.: cold-
  // start pelo toque no banner). Processado por [tryOpenPendingBudget].
  String? _pendingBudgetId;

  /// Token FCM atual em **memória volátil**. Obtido já no `initialize()`
  // (startup do app), ANTES do login — o FCM só precisa do Firebase
  // inicializado, não do usuário. Guardar aqui desacopla "pegar o token"
  // de "salvar o token": só salvamos no Firestore **depois do login",
  // quando já sabemos o `uid` do dono. Sobrevive em memória entre o
  // startup e o login (e entre logins) mas some se o app é fechado —
  // por isso mesmo, no próximo startup ele é re-obtido e re-salvo.
  String? _fcmToken;

  /// `uid` do dono atualmente vinculado (setado em
  // `startBudgetApprovalListener`). Usado para re-persistir o token
  // automaticamente quando ele renova via `onTokenRefresh`.
  String? _boundOwnerUid;

  /// Observa renovações do token FCM para manter persistido o token atual
  // do dono (a Cloud Function precisa do token válido para enviar o push).
  StreamSubscription<String>? _tokenRefreshSub;

  /// Inicializa tudo. Deve ser chamado após `Firebase.initializeApp()`.
  Future<void> initialize() async {
    // 1) Inicializa o plugin de notificações locais (Android usa o ícone do app).
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    // O callback `onDidReceiveNotificationResponse` dispara quando o usuário
    // **toca** numa notificação local (as que nós mesmos mostramos em
    // foreground) — abre o orçamento a partir do payload (`ORCAMENTO_ID`).
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2) Cria o canal de alta importância em runtime (Android 8+ exige canal).
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ));

    // 3) iOS: permite que FCM mostre alert/badge/som em foreground.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4) Registra o handler de background (mensagens data-only / processamento
    //    em isolate). Para mensagens com `notification` payload o próprio
    //    sistema exibe; este handler garante robustez para `data`.
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 5) Foreground: chega via onMessage. No Android o FCM **não** exibe
    //    notificações `notification` em foreground sozinho, então mostramos
    //    uma notificação local nós mesmos.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6) Background -> usuário toca no banner: o sistema abriu o app e o FCM
    //    entrega a mensagem aqui. Abre o orçamento.
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 7) Terminated (app fechado) -> usuário toca no banner: precisamos ler
    //    a mensagem inicial que abriu o app. Best-effort; o deep-link é
    //    consumido depois do login via [tryOpenPendingBudget].
    unawaited(_handleInitialMessage());

    // 8) Permissão + token (memória volátil).
    //    O token é obtido aqui no startup, ANTES do login, e guardado em
    //    `_fcmToken`. A persistência no Firestore só acontece DEPOIS do
    //    login (precisa do `uid` do dono) — ver `startBudgetApprovalListener`.
    //
    //    Permissão de notificação:
    //    - Android 13+ (API 33): exige POST_NOTIFICATIONS em runtime. Já
    //      declarado no AndroidManifest. O `requestPermission()` do FCM
    //      pede essa permissão nessas versões, mas o caminho canônico e
    //      mais robusto é pedir também via `flutter_local_notifications`
    //      (`requestNotificationsPermission()`), que retorna o status real
    //      concedido/negado. Sem isso, em Android 13/14/15/16 o push pode
    //      chegar do FCM mas **não ser exibido** na bandeja se o usuário
    //      negou a permissão.
    //    - iOS: `requestPermission()` pede alert/badge/som. O token APNs
    //      é obtido automaticamente pelo FCM quando o entitlement
    //      `aps-environment` + `UIBackgroundModes: remote-notification`
    //      estão configurados (ver Info.plist e Runner*.entitlements).
    if (kIsWeb) {
      await FirebaseMessaging.instance.requestPermission();
    } else {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android: pede POST_NOTIFICATIONS (API 33+) explicitamente via
        // flutter_local_notifications e, como fallback, também via FCM.
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted =
            await androidPlugin?.requestNotificationsPermission();
        if (kDebugMode) {
          debugPrint('Android POST_NOTIFICATIONS concedido? $granted');
        }
        await FirebaseMessaging.instance.requestPermission();
      }
    }
    // iOS: garante que o token APNs esteja disponível (o FCM só consegue
    // entregar push no Apple se houver token APNs + chave APNs Auth no
    // Console do Firebase). Best-effort; em Android/Web isto é no-op.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (kDebugMode) {
        debugPrint('APNs token: $apnsToken');
      }
    }
    final String? token = await _acquireTokenWithRetry();
    _fcmToken = token;
    if (kDebugMode) {
      debugPrint('FCM token (memória volátil): $token');
    }
    // Observa renovações: atualiza a memória e, se já houver dono vinculado,
    // re-salva no Firestore (token mudou → a Cloud Function precisa do novo).
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _fcmToken = t;
      final owner = _boundOwnerUid;
      if (owner != null && owner.isNotEmpty) {
        unawaited(_persistFcmToken(owner));
      }
    });
  }

  /// Token FCM atual (em memória volátil). Retorna o token em cache se já
  /// foi obtido no startup; caso contrário, busca agora (fallback) e cacheia.
  Future<String?> currentToken() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) return _fcmToken;
    final t = await _acquireTokenWithRetry();
    _fcmToken = t;
    return t;
  }

  /// Busca o token FCM com **retry**. No Android (especialmente 13+/15) o
  /// `getToken()` pode retornar `null` na primeira tentativa se o Google
  /// Play Services ainda não estiver pronto (o handshake de registro é
  /// assíncrono) — daí o token nunca seria persistido e o push não chegaria
  /// naquele device. Aqui tentamos algumas vezes com um pequeno delay entre
  /// cada; assim que o token aparece, cacheamos e retornamos.
  ///
  /// Se mesmo após todas as tentativas vier `null`, o problema é quase
  /// sempre de **configuração** (não de código): o SHA-1 do certificado de
  /// assinatura do app (debug e/ou release) não está cadastrado no projeto
  /// Firebase → o Play Services recusa com `DEVELOPER_ERROR` (log visível:
  /// `Phenotype.API is not available on this device`). Nesse caso é preciso
  /// adicionar o SHA-1 no Console do Firebase e baixar um `google-services
  /// .json` atualizado — nenhuma quantidade de retry resolve isso.
  Future<String?> _acquireTokenWithRetry({
    int maxAttempts = 6,
    Duration delay = const Duration(seconds: 2),
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final t = await FirebaseMessaging.instance.getToken();
        if (t != null && t.isNotEmpty) {
          if (kDebugMode && attempt > 1) {
            debugPrint('FCM token obtido na tentativa $attempt');
          }
          return t;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FCM getToken() falhou (tentativa $attempt): $e');
        }
      }
      if (attempt < maxAttempts) {
        await Future<void>.delayed(delay);
      }
    }
    if (kDebugMode) {
      debugPrint(
          'FCM token NULO após $maxAttempts tentativas. Verifique: '
          '(1) SHA-1 do certificado cadastrado no Console do Firebase; '
          '(2) google-services.json atualizado; '
          '(3) Play Services no dispositivo.');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Foreground (app aberto)
  // ---------------------------------------------------------------------------

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString() ?? '';

    // Título/corpo vindos do payload `notification` (enviado pela Cloud
    // Function) ou, fallback, do `data`.
    final title = notification?.title ?? message.data['TITULO']?.toString();
    final body = notification?.body ?? message.data['MENSAGEM']?.toString();
    if (title == null && body == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      payload: orcamentoId.isEmpty ? null : orcamentoId,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background (app minimizado) e Terminated (app fechado)
  // ---------------------------------------------------------------------------

  void _onMessageOpenedApp(RemoteMessage message) {
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString();
    if (orcamentoId != null && orcamentoId.isNotEmpty) {
      unawaited(_openBudget(orcamentoId));
    }
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;
    final orcamentoId = message.data['ORCAMENTO_ID']?.toString();
    if (orcamentoId != null && orcamentoId.isNotEmpty) {
      // O dono pode não estar logado ainda neste momento (auto-login ainda
      // não rodou). Guarda como pendente; [tryOpenPendingBudget] abre depois.
      _pendingBudgetId = orcamentoId;
    }
  }

  // ---------------------------------------------------------------------------
  // Toque no banner da notificação -> abre o orçamento aprovado/reprovado
  // ---------------------------------------------------------------------------

  /// Recebe a chave global do navigator (de `main.dart`) e, se houver um
  /// orçamento pendente (toque que chegou antes do navigator estar pronto),
  /// tenta abrir agora. Idempotente.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    tryOpenPendingBudget();
  }

  /// Tenta abrir um orçamento pendente (toque no banner antes do navigator/
  /// dono estarem prontos — cold-start pelo toque). Deve ser chamado em
  /// momentos seguros: após o login (quando `uid.user` está disponível) e/ou
  /// quando a tela principal (`MainTabView`) é construída. Idempotente.
  void tryOpenPendingBudget() {
    final pending = _pendingBudgetId;
    if (pending == null || pending.isEmpty) return;
    final key = _navigatorKey;
    if (key == null || key.currentContext == null) return;
    final owner = uid.user;
    if (owner == null || owner.isEmpty) return;
    _pendingBudgetId = null;
    unawaited(_openBudget(pending));
  }

  void _onNotificationTap(NotificationResponse response) {
    final budgetId = response.payload;
    if (budgetId == null || budgetId.isEmpty) return;
    unawaited(_openBudget(budgetId));
  }

  /// Abre o orçamento [budgetId] (mesmo id gravado em `ORCAMENTO_ID` no
  /// documento de notificação) na tela `BudgetTabView`, reutilizando o
  /// `HttpRequest.getInformationOrcamento1` do app mobile — nenhuma regra
  /// paralela. Se o navigator ainda não estiver pronto, guarda como pendente.
  Future<void> _openBudget(String budgetId) async {
    final key = _navigatorKey;
    if (key == null || key.currentContext == null) {
      _pendingBudgetId = budgetId;
      return;
    }
    // Só faz sentido abrir se o dono está logado (caso contrário o listener
    // nem estaria ativo e não haveria notificação para tocar).
    final owner = uid.user;
    if (owner == null || owner.isEmpty) {
      _pendingBudgetId = budgetId;
      return;
    }
    try {
      budget.IDORCAMENTO = budgetId;
      final customer = await HttpRequest().getInformationOrcamento1();
      customer.id ??= budgetId;
      final context = key.currentContext!;
      if (!context.mounted) {
        _pendingBudgetId = budgetId;
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BudgetTabView(item: customer)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('open budget from notification failed: $e');
      // Em falha de leitura, mesmo assim tenta abrir com id preenchido para
      // o dono não ficar sem resposta ao toque.
      final context = key.currentContext;
      if (context != null && context.mounted) {
        final fallback = CustomerInfo()..id = budgetId;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BudgetTabView(item: fallback)),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Token FCM do dono (usado pela Cloud Function para enviar o push)
  // ---------------------------------------------------------------------------

  /// Chamado depois que o dono faz login (quando `global_uid_user.user` fica
  /// disponível). **Salva** o token FCM (que já está em memória volátil desde o
  /// startup) em `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}` — um doc
  /// por dispositivo, lido pela Cloud Function para fan-out a todos os
  /// devices. Idempotente: mesmo token = mesmo id de doc, nunca duplica.
  ///
  /// O token é obtido no `initialize()` (antes do login) e guardado em
  /// `_fcmToken`; aqui só persistimos o que já temos em memória. Se ainda
  /// não houver token em memória (caso raro), busca agora como fallback.
  void startBudgetApprovalListener(String ownerUid) {
    // Não roda no Web público (lá só há o fluxo do cliente, não o do dono).
    if (kIsWeb) return;
    // Defesa de fronteira: uid vazio/nulo geria path inválido no Firestore
    // (`EMPRESAS//USERS//FCM/...`) e quebraria a persistência. Nunca chama
    // `_persistFcmToken` sem um uid válido.
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('startBudgetApprovalListener ignorado: ownerUid vazio');
      }
      return;
    }
    _boundOwnerUid = ownerUid.trim();
    // Persiste o token que JÁ está em memória volátil desde o startup
    // (`_fcmToken`, obtido em `initialize()` ANTES do login). Não gera um
    // token novo aqui — só grava no Firebase o que já temos em memória.
    unawaited(_persistFcmToken(_boundOwnerUid!));
    // Após o login o dono está autenticado: tenta consumir um orçamento
    // pendente de abrir (cold-start pelo toque no banner).
    tryOpenPendingBudget();
  }

  /// Encerra vínculos (ex.: logout). Idempotente.
  void stopBudgetApprovalListener() {
    _boundOwnerUid = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  /// Lê a lista de tokens FCM cadastrados para o dono (um por dispositivo)
  /// em `EMPRESAS/{uid}/USERS/{uid}/FCM` (coleção onde cada doc tem id = token).
  /// Usado em `_getUserInfo` para expor a lista em `InfoUser.TOKENS` /
  /// `global_uid_user.tokens` — os "dados do usuário" passam a conter cada
  /// token push cadastrado.
  Future<List<String>> loadFcmTokens(String ownerUid) async {
    // Defesa de fronteira: uid vazio/nulo geraria path de coleção inválido
    // (`EMPRESAS//USERS//FCM`) e lançaria `Invalid argument(s):
    // A collection path must point to a valid collection`. Retorna lista
    // vazia em vez de tentar o acesso.
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('loadFcmTokens ignorado: ownerUid vazio');
      }
      return const <String>[];
    }
    final uid = ownerUid.trim();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('EMPRESAS/$uid/USERS/$uid/FCM')
          .get();
      return snap.docs.map((d) => d.id).toList(growable: false);
    } catch (e) {
      if (kDebugMode) debugPrint('load FCM tokens failed: $e');
      return const <String>[];
    }
  }

  /// Persiste o token FCM atual do dono na LISTA de tokens
  /// `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}` — **um doc por
  /// dispositivo**, id do doc = próprio token (idempotente: mesmo token
  /// = mesmo doc, nunca duplica). A Cloud Function lê essa coleção e
  /// envia o push a **todos** os devices do dono (multi-device).
  ///
  /// Só o token, sem `ATUALIZADO_EM` nem outros campos — o doc existe só
  /// pra marcar "este device está logado e quer receber push".
  ///
  /// Este é o método **público** (chamado tanto no pós-login quanto no
  /// dashboard como redundância) — o trabalho real está em [_persistFcmToken].
  /// Idempotente: pode chamar quantas vezes quiser.
  Future<void> persistCurrentTokenToFirebase(String ownerUid) =>
      _persistFcmToken(ownerUid);

  Future<void> _persistFcmToken(String ownerUid) async {
    // Defesa de fronteira: uid vazio/nulo geraria path de documento inválido
    // (`EMPRESAS//USERS//FCM/{token}`) e lançaria `Invalid
    // argument(s): A document path must point to a valid document`.
    if (ownerUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('persist FCM token ignorado: ownerUid vazio');
      }
      return;
    }
    final uid = ownerUid.trim();
    if (kDebugMode) {
      debugPrint('[_persistFcmToken] inicio — uid=$uid');
    }
    try {
      // Token obtido no startup (memória volátil `_fcmToken`). Se ainda
      // não houver, `currentToken()` busca agora com retry. Sem token =
      // nada a salvar (e o push não chegaria neste device de qq forma).
      final String? token = await currentToken();
      if (kDebugMode) {
        debugPrint('[_persistFcmToken] token obtido: '
            '${token == null ? "NULL" : (token.isEmpty ? "VAZIO" : token)}');
      }
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('persist FCM token: SEM TOKEN — não vai salvar nada. '
              'Provável causa: SHA-1 do certificado não cadastrado no '
              'Firebase / google-services.json desatualizado.');
        }
        return;
      }
      final db = FirebaseFirestore.instance;
      final docRef = db.doc('EMPRESAS/$uid/USERS/$uid/FCM/$token');
      if (kDebugMode) {
        debugPrint('[_persistFcmToken] gravando em: ${docRef.path}');
      }
      // Grava na coleção `FCM`. Sem `ATUALIZADO_EM`, sem doc legado
      // `TOKEN`. O id do documento é o próprio token — gravação
      // idempotente: cada device logado cria/existe um doc.
      await docRef.set({'TOKEN': token}, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint('FCM token SALVO na lista: '
            'EMPRESAS/$uid/USERS/$uid/FCM/$token');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('persist FCM token failed: $e');
        debugPrint('stack: $st');
      }
    }
  }
}

/// Handler top-level (obrigatório ser top-level, não método de instância)
/// para mensagens FCM em background, registrado via
/// `FirebaseMessaging.onBackgroundMessage`. Anotado com
/// `@pragma('vm:entry-point')` para o Flutter conseguir recriar o entry-point
/// num isolate separado. Para mensagens com `notification` payload, o
/// próprio sistema exibe a notificação na bandeja; este handler garante
/// processamento de `data` (e logging em debug).
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId} '
        'orcamento=${message.data['ORCAMENTO_ID']}');
  }
}
