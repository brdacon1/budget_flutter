/**
 * Cloud Functions do OfLite — notificações de aprovação/reprovação.
 *
 * Problema que isto resolve: o app mobile do dono só conseguia saber que o
 * cliente aprovou/reprovou um orçamento pela Web quando o app estava ABERTO
 * (listener do Firestore em tempo real não roda com o app fechado).
 *
 * Solução: sempre que o fluxo Web grava um documento em
 *   EMPRESAS/{ownerUid}/USERS/{ownerUid}/NOTIFICACOES/{notifId}
 * (documento com TITULO, MENSAGEM, ORCAMENTO_ID, STATUS), esta função
 * dispara, lê a LISTA de tokens FCM do dono em
 *   EMPRESAS/{ownerUid}/USERS/{ownerUid}/FCM/{token}
 * (um documento por dispositivo, gravado pelo app a cada login/início) e
 * envia uma mensagem FCM v1 (`notification` + `data`) para TODOS os tokens —
 * assim o Android exibe a notificação na bandeja do sistema MESMO com o app
 * fechado, em TODOS os dispositivos onde o dono fez login (multi-device), e
 * ao tocar o dono é levado ao orçamento (deep-link via `data.ORCAMENTO_ID`,
 * tratado no app por getInitialMessage / onMessageOpenedApp).
 *
 * Tokens inválidos/expirados (FCM v1 retorna `UNREGISTERED` etc.) são
 * removidos da lista automaticamente, mantendo-a limpa.
 *
 * IMPORTANTE:
 *  - Cloud Functions gen2 exige o plano Blaze (pay-as-you-go) do Firebase.
 *  - O trigger deve estar na MESMA REGIÃO do banco Firestore do projeto.
 *    Ajuste `REGION` abaixo se o seu banco não for `southamerica-east1`.
 *    Padrão de novos projetos costuma ser `us-central1` (nam5).
 *
 * Deploy:
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");
const cors = require("cors")({
  // Domínios oficiais do app + localhost para teste local com `firebase emulators:start`.
  origin: [
    "https://orcamentofacil-lite.web.app",
    "https://orcamentofacil-lite.firebaseapp.com",
    "http://localhost:5000",
    "http://localhost:3000",
  ],
  methods: ["POST", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Accept", "Authorization", "X-Requested-With"],
  credentials: false,
  optionsSuccessStatus: 204,
});

// AJUSTE: região do seu Firestore. Padrão para projetos brasileiros via
// console costuma ser "southamerica-east1"; projetos antigos/defaults usam
// "us-central1". Se o deploy reclamar de região, troque aqui.
// >>> SE O TRIGGER NÃO DISPARA (não aparece NADA nos logs da função ao
//     aprovar na Web), troque REGION para a região EXATA do seu Firestore
//     (Console Firebase -> Firestore Database -> topo mostra a região).
const REGION = "southamerica-east1";

initializeApp();
const db = getFirestore();
const auth = getAuth();
const messaging = getMessaging();

/**
 * Valida o `Authorization: Bearer <Firebase ID Token>` da requisição.
 * Retorna o token decodificado ou `null` (inválido, expirado ou revogado).
 */
async function verifyBearer(req) {
  const idToken = String(req.get("authorization") || "").replace(/^Bearer\s+/i, "");
  if (!idToken) return null;
  try {
    return await auth.verifyIdToken(idToken, true);
  } catch (_) {
    return null;
  }
}

/**
 * Códigos de erro do FCM v1 que indicam token inválido/expirado e que o
 * token deve ser removido da lista (a pessoa desinstalou o app, limpou
 * dados, ou o token expirou). Referência:
 *   https://firebase.google.com/docs/cloud-messaging/manage-tokens#detect-invalid-client-tokens
 */
// NÃO incluir "invalid-argument": ele também é retornado quando o PAYLOAD é
// inválido, e isso apagava TODOS os tokens (Android e iOS) da lista.
const INVALID_TOKEN_CODES = [
  "registration-token-not-registered",
  "invalid-registration-token",
];

// ---------------------------------------------------------------------------
// Envio FCM centralizado (usado pelo trigger e pelo endpoint de teste)
// ---------------------------------------------------------------------------

/**
 * Lê os tokens em EMPRESAS/{ownerUid}/USERS/{ownerUid}/FCM (coleção onde
 * cada doc tem id = token) e envia um push FCM v1 para TODOS eles.
 * Retorna um relatório detalhado para diagnóstico.
 */
async function sendFcmToOwner(ownerUid, { title, body, orcamentoId, status }) {
  const report = {
    ownerUid,
    tokensLidos: 0,
    enviados: 0,
    falhas: [],
    invalidosRemovidos: 0,
  };

  const tokensCol = db
    .collection(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM`);

  let tokens = [];
  try {
    const colSnap = await tokensCol.get();
    // Tenta id do doc (formato novo) E campo TOKEN (compat caso o doc tenha
    // sido gravado de outra forma). Cada device = um token.
    tokens = colSnap.docs
      .map((d) => {
        const id = String(d.id || "");
        const field = d.get && d.get("TOKEN");
        return id && id.length > 20 ? id : (field ? String(field) : id);
      })
      .filter((t) => t && t.length > 0);
    report.tokensLidos = tokens.length;
    logger.info("[FCM] tokens lidos", { ownerUid, total: tokens.length });
  } catch (e) {
    logger.error("[FCM] erro ao ler lista de tokens", { ownerUid, error: String(e) });
    report.falhas.push({ etapa: "lerTokens", erro: String(e) });
    return report;
  }

  if (tokens.length === 0) {
    logger.warn("[FCM] dono SEM token cadastrado", {
      ownerUid,
      path: `EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM`,
    });
    return report;
  }

  const message = {
    notification: { title, body },
    data: {
      ORCAMENTO_ID: orcamentoId || "",
      STATUS: status || "",
      TIPO: "budget_approval",
    },
    android: {
      priority: "high",
      notification: { channelId: "high_importance_channel", sound: "default" },
    },
    apns: {
      headers: { "apns-priority": "10", "apns-push-type": "alert" },
      payload: { aps: { sound: "default", badge: 1 } },
    },
  };

  const invalidTokens = [];
  try {
    const resp = await messaging.sendEachForMulticast({
      ...message,
      tokens,
    });
    report.enviados = resp.successCount;
    logger.info("[FCM] resultado multicast", {
      ownerUid,
      success: resp.successCount,
      failure: resp.failureCount,
    });
    for (let i = 0; i < resp.responses.length; i++) {
      const r = resp.responses[i];
      if (r.success) continue;
      const code = String(
        (r.error && (r.error.code || (r.error.errorInfo && r.error.errorInfo.code))) || ""
      );
      const msg = String((r.error && r.error.message) || "");
      logger.error("[FCM] falha por token", {
        ownerUid,
        token: tokens[i],
        code,
        message: msg,
      });
      report.falhas.push({ token: tokens[i], code, message: msg });
      const shouldRemove = INVALID_TOKEN_CODES.some((c) => code.endsWith(c));
      if (shouldRemove) invalidTokens.push(tokens[i]);
    }
  } catch (e) {
    logger.error("[FCM] erro no sendEachForMulticast", { ownerUid, error: String(e) });
    report.falhas.push({ etapa: "multicast", erro: String(e) });
    return report;
  }

  if (invalidTokens.length > 0) {
    const batch = db.batch();
    for (const t of invalidTokens) {
      batch.delete(db.doc(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM/${t}`));
    }
    try {
      await batch.commit();
      report.invalidosRemovidos = invalidTokens.length;
      logger.info("[FCM] tokens inválidos removidos", {
        ownerUid,
        removidos: invalidTokens.length,
      });
    } catch (e) {
      logger.error("[FCM] erro ao remover inválidos", { ownerUid, error: String(e) });
    }
  }

  return report;
}

// ---------------------------------------------------------------------------
// Endpoint HTTP de TESTE (diagnóstico) — isola trigger vs envio FCM
// ---------------------------------------------------------------------------
//
// Chame (qualquer HTTP client) com JSON:
//   POST https://REGION-<projeto>.cloudfunctions.net/sendTestPush
//   { "ownerUid": "<UID DO DONO>", "orcamentoId": "123" }
//
// Ele NÃO depende do trigger do Firestore: lê os tokens e envia o push
// direto. Se isto enviar mas o trigger não, o problema é a REGIÃO/path do
// trigger. Se isto também não enviar, o problema é FCM (token inválido,
// permissão, SHA-1, projeto errado).
exports.sendTestPush = onRequest(
  { region: REGION },
  async (req, res) => {
    cors(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({ ok: false, erro: "Use POST." });
        return;
      }
      // Exige login: só envia push de teste para os PRÓPRIOS dispositivos.
      const decoded = await verifyBearer(req);
      if (!decoded) {
        res.status(401).json({ ok: false, erro: "Não autenticado." });
        return;
      }
      const ownerUid = decoded.uid;
      const orcamentoId = String(req.body?.orcamentoId || "").trim();
      logger.info("[TESTE] sendTestPush chamado", { ownerUid, orcamentoId });
      const report = await sendFcmToOwner(ownerUid, {
        title: "Teste de Push OfLite",
        body: "Teste de envio",
        orcamentoId: orcamentoId || "TESTE",
        status: "TESTE",
      });
      res.status(200).json({ ok: true, report });
    });
  }
);

exports.onBudgetApprovalNotification = onDocumentCreated(
  {
    document:
      "EMPRESAS/{ownerUid}/USERS/{ownerUid}/NOTIFICACOES/{notifId}",
    region: REGION,
  },
  async (event) => {
    logger.info("[TRIGGER] onBudgetApprovalNotification DISPAROU", {
      ownerUid: event.params.ownerUid,
      notifId: event.params.notifId,
      path: event.data && event.data.ref && event.data.ref.path,
    });
    const snap = event.data;
    if (!snap) {
      logger.warn("[TRIGGER] sem snapshot no evento");
      return;
    }
    const data = snap.data() || {};
    const ownerUid = event.params.ownerUid;

    const title = String(data.TITULO || "Orçamento");
    const body = String(data.MENSAGEM || "");
    const orcamentoId = String(data.ORCAMENTO_ID || "");
    const status = String(data.STATUS || "");

    logger.info("[TRIGGER] payload notificação", {
      ownerUid, title, body, orcamentoId, status,
    });

    if (!title && !body) {
      logger.warn("[TRIGGER] notificação sem título/mensagem, ignorando", { ownerUid });
      return;
    }

    const report = await sendFcmToOwner(ownerUid, { title, body, orcamentoId, status });
    logger.info("[TRIGGER] FCM fan-out concluído", {
      ownerUid, orcamentoId, status,
      total: report.tokensLidos, enviados: report.enviados,
      invalidos: report.invalidosRemovidos, falhas: report.falhas.length,
    });
  }
);

// ---------------------------------------------------------------------------
// Exclusão de conta e dados (LGPD / Google Play requisito)
// ---------------------------------------------------------------------------
// Endpoint público para exclusão completa de conta + dados pessoais.
// Recebe o email do usuário, localiza o UID, remove todos os documentos
// Firestore (inclusive subcoleções) e deleta o usuário do Firebase Auth.
// ---------------------------------------------------------------------------

/**
 * Deleta recursivamente um documento e todas as suas subcoleções.
 * Usa a API interna do Firestore (recursiveDelete disponível no Admin SDK).
 */
async function deleteDocRecursive(docRef) {
  try {
    await db.recursiveDelete(docRef);
  } catch (e) {
    logger.error("[deleteAccount] erro em recursiveDelete", { path: docRef.path, error: String(e) });
    throw e;
  }
}

// Login precisa ser recente para excluir (evita usar um token antigo/vazado).
const DELETE_MAX_AUTH_AGE_SECONDS = 5 * 60;

exports.deleteAccount = onRequest(
  { region: REGION, timeoutSeconds: 540, memory: "1GiB" },
  async (req, res) => {
    cors(req, res, async () => {
      if (req.method !== "POST") {
        res.status(405).json({ ok: false, erro: "Método não permitido. Use POST." });
        return;
      }

      // Só o PRÓPRIO usuário, autenticado agora, pode excluir a conta.
      // Nunca aceitar e-mail/uid vindo do corpo da requisição.
      const decoded = await verifyBearer(req);
      if (!decoded) {
        res.status(401).json({ ok: false, erro: "Não autenticado." });
        return;
      }
      const authAge = Math.floor(Date.now() / 1000) - Number(decoded.auth_time || 0);
      if (authAge > DELETE_MAX_AUTH_AGE_SECONDS) {
        res.status(401).json({ ok: false, erro: "Faça login novamente para excluir a conta." });
        return;
      }

      const uid = decoded.uid;
      logger.info("[deleteAccount] solicitação autenticada", { uid });
      const deletados = [];
      const falhas = [];

      const steps = [
        // EMPRESAS/{uid} com TODAS as subcoleções (inclui USERS/{uid}/ORCAMENTOS etc.)
        ["EMPRESAS", () => deleteDocRecursive(db.doc(`EMPRESAS/${uid}`))],
        ["USUARIOS", () => db.doc(`USUARIOS/${uid}`).delete()],
        ["SHARE_LINKS", async () => {
          const links = await db.collection("SHARE_LINKS").where("ownerUid", "==", uid).get();
          await Promise.all(links.docs.map((d) => d.ref.delete()));
        }],
        ["auth/user", () => auth.deleteUser(uid)],
      ];

      for (const [name, run] of steps) {
        try {
          await run();
          deletados.push(name);
        } catch (e) {
          falhas.push({ path: name, erro: e.message });
          logger.error("[deleteAccount] falha", { uid, step: name, error: e.message });
        }
      }

      if (falhas.length === 0) {
        res.status(200).json({ ok: true, message: "Conta e dados removidos com sucesso." });
      } else {
        res.status(500).json({ ok: false, erro: "Algumas etapas da exclusão falharam.", falhas });
      }
    });
  }
);

// ---------------------------------------------------------------------------
// Link público de orçamento (código curto + telefone validado no servidor)
// ---------------------------------------------------------------------------
require("./share_link").registerShareLinkFunctions(exports, REGION);
