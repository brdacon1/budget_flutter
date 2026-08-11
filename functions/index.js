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
const admin = require("firebase-admin");

// AJUSTE: região do seu Firestore. Padrão para projetos brasileiros via
// console costuma ser "southamerica-east1"; projetos antigos/defaults usam
// "us-central1". Se o deploy reclamar de região, troque aqui.
// >>> SE O TRIGGER NÃO DISPARA (não aparece NADA nos logs da função ao
//     aprovar na Web), troque REGION para a região EXATA do seu Firestore
//     (Console Firebase -> Firestore Database -> topo mostra a região).
const REGION = "southamerica-east1";

admin.initializeApp();

/**
 * Códigos de erro do FCM v1 que indicam token inválido/expirado e que o
 * token deve ser removido da lista (a pessoa desinstalou o app, limpou
 * dados, ou o token expirou). Referência:
 *   https://firebase.google.com/docs/cloud-messaging/manage-tokens#detect-invalid-client-tokens
 */
const INVALID_TOKEN_CODES = [
  "UNREGISTERED",
  "registration-token-not-registered",
  "INVALID_ARGUMENT",
  "invalid-argument",
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

  const tokensCol = admin
    .firestore()
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
      notification: {
        channelId: "high_importance_channel",
        icon: "@mipmap/ic_launcher",
        priority: "high",
        defaultVibrateTimings: true,
      },
    },
  };

  const invalidTokens = [];
  try {
    const resp = await admin.messaging().sendEachForMulticast({
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
      const shouldRemove = INVALID_TOKEN_CODES.some((c) =>
        code.toUpperCase().includes(c.toUpperCase())
      );
      if (shouldRemove) invalidTokens.push(tokens[i]);
    }
  } catch (e) {
    logger.error("[FCM] erro no sendEachForMulticast", { ownerUid, error: String(e) });
    report.falhas.push({ etapa: "multicast", erro: String(e) });
    return report;
  }

  if (invalidTokens.length > 0) {
    const db = admin.firestore();
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
    // CORS liberal p/ teste (não importa em prod aqui).
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.status(204).send("");
      return;
    }
    const ownerUid = String(req.body?.ownerUid || "").trim();
    const orcamentoId = String(req.body?.orcamentoId || "").trim();
    if (!ownerUid) {
      res.status(400).json({ ok: false, erro: "ownerUid é obrigatório" });
      return;
    }
    logger.info("[TESTE] sendTestPush chamado", { ownerUid, orcamentoId });
    const report = await sendFcmToOwner(ownerUid, {
      title: "Teste de Push OfLite",
      body: `Teste de envio para ${ownerUid}`,
      orcamentoId: orcamentoId || "TESTE",
      status: "TESTE",
    });
    logger.info("[TESTE] report", report);
    res.status(200).json({ ok: true, report });
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
