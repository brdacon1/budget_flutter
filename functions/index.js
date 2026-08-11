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
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

// AJUSTE: região do seu Firestore. Padrão para projetos brasileiros via
// console costuma ser "southamerica-east1"; projetos antigos/defaults usam
// "us-central1". Se o deploy reclamar de região, troque aqui.
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

exports.onBudgetApprovalNotification = onDocumentCreated(
  {
    document:
      "EMPRESAS/{ownerUid}/USERS/{ownerUid}/NOTIFICACOES/{notifId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.info("sem snapshot no evento");
      return;
    }
    const data = snap.data() || {};
    const ownerUid = event.params.ownerUid;

    const title = String(data.TITULO || "Orçamento");
    const body = String(data.MENSAGEM || "");
    const orcamentoId = String(data.ORCAMENTO_ID || "");
    const status = String(data.STATUS || "");

    if (!title && !body) {
      logger.info("notificação sem título/mensagem, ignorando", { ownerUid });
      return;
    }

    // Lê a LISTA de tokens FCM do dono (um por dispositivo) em
    // EMPRESAS/{ownerUid}/USERS/{ownerUid}/FCM. O app grava um doc
    // por token (id do doc = token) a cada login — assim o push chega a
    // TODOS os devices conectados, não importa quantos sejam.
    const tokensCol = admin
      .firestore()
      .collection(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM`);

    let tokens = [];
    try {
      const colSnap = await tokensCol.get();
      tokens = colSnap.docs
        .map((d) => String(d.id))
        .filter((t) => t && t.length > 0);
    } catch (e) {
      logger.error("erro ao ler lista de tokens FCM", e);
    }

    if (tokens.length === 0) {
      logger.info("dono sem token FCM cadastrado", { ownerUid });
      return;
    }

    // Monta a mensagem FCM v1. `notification` faz o Android exibir na bandeja
    // mesmo com o app fechado; `data` carrega o ORCAMENTO_ID para deep-link.
    const baseMessage = {
      notification: { title, body },
      data: {
        ORCAMENTO_ID: orcamentoId,
        STATUS: status,
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

    // Envio em lote para TODOS os tokens (FCM v1 multicast). O
    // `sendEachForMulticast` usa a FCM v1 HTTP API por baixo dos panos
    // (https://fcm.googleapis.com/v1/...) via Admin SDK, e retorna uma
    // resposta por token — permitindo remover tokens inválidos da lista.
    let successCount = 0;
    const invalidTokens = [];
    try {
      const resp = await admin.messaging().sendEachForMulticast({
        ...baseMessage,
        tokens,
      });
      successCount = resp.successCount;
      for (let i = 0; i < resp.responses.length; i++) {
        const r = resp.responses[i];
        if (r.success) continue;
        const code = String(
          (r.error && (r.error.code || (r.error.errorInfo && r.error.errorInfo.code))) || ""
        );
        const shouldRemove = INVALID_TOKEN_CODES.some((c) =>
          code.toUpperCase().includes(c.toUpperCase())
        );
        if (shouldRemove) {
          invalidTokens.push(tokens[i]);
        } else {
          logger.error("falha ao enviar FCM (transitória?)", {
            token: tokens[i],
            code,
            message: r.error && r.error.message,
          });
        }
      }
    } catch (e) {
      logger.error("falha ao enviar FCM multicast", e);
    }

    // Remove tokens inválidos da lista para mantê-la limpa (best-effort).
    if (invalidTokens.length > 0) {
      const db = admin.firestore();
      const batch = db.batch();
      for (const t of invalidTokens) {
        batch.delete(
          db.doc(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM/${t}`)
        );
      }
      try {
        await batch.commit();
        logger.info("tokens inválidos removidos da lista", {
          ownerUid,
          removidos: invalidTokens.length,
        });
      } catch (e) {
        logger.error("erro ao remover tokens inválidos", e);
      }
    }

    logger.info("FCM fan-out concluído", {
      ownerUid,
      orcamentoId,
      status,
      total: tokens.length,
      enviados: successCount,
      invalidos: invalidTokens.length,
    });
  }
);
