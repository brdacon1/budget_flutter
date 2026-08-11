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
 * dispara, lê o token FCM do dono em
 *   EMPRESAS/{ownerUid}/USERS/{ownerUid}/FCM/TOKEN
 * e envia uma mensagem FCM com `notification` + `data`. Assim o Android
 * exibe a notificação na bandeja do sistema MESMO com o app fechado, e ao
 * tocar o dono é levado ao orçamento (deep-link via `data.ORCAMENTO_ID`,
 * tratado no app por getInitialMessage / onMessageOpenedApp).
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

    // Lê o token FCM mais recente do dono (gravado pelo app em FCM/TOKEN).
    const tokenRef = admin
      .firestore()
      .doc(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/FCM/TOKEN`);

    let token = "";
    try {
      const tokenDoc = await tokenRef.get();
      if (tokenDoc.exists) {
        token = String(tokenDoc.get("TOKEN") || "");
      }
    } catch (e) {
      logger.error("erro ao ler token FCM", e);
    }

    if (!token) {
      logger.info("dono sem token FCM cadastrado", { ownerUid });
      return;
    }

    // Monta a mensagem FCM. `notification` faz o Android exibir na bandeja
    // mesmo com o app fechado; `data` carrega o ORCAMENTO_ID para deep-link.
    const message = {
      token,
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

    try {
      const resp = await admin.messaging().send(message);
      logger.info("FCM enviado", {
        ownerUid,
        orcamentoId,
        messageId: resp,
      });
    } catch (e) {
      logger.error("falha ao enviar FCM", e);
    }
  }
);
