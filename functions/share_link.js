/**
 * Link público de orçamento (aprovação pelo cliente na Web).
 *
 * Substitui o link antigo `/orcamento/{id}?token={ID Token do dono}`, que
 * entregava a SESSÃO inteira do dono a quem recebesse o link.
 *
 * Agora:
 *  - O app do dono chama `createShareLink` (autenticado + App Check) e recebe
 *    um código curto e aleatório: `https://<host>/o/{code}`.
 *  - O código fica em `SHARE_LINKS/{code}` (coleção fechada para clientes)
 *    com escopo de UM orçamento, validade e contador de tentativas.
 *  - A Web chama `openShareLink(code, phone)`: o telefone é comparado AQUI no
 *    servidor e só então os dados daquele orçamento são devolvidos.
 *  - A Web chama `respondShareLink(code, phone, status)`: altera apenas o
 *    `STATUS` daquele orçamento e cria a notificação do dono.
 *
 * Nenhum token de usuário sai do app.
 */

const crypto = require("crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getAppCheck } = require("firebase-admin/app-check");

const COLLECTION = "SHARE_LINKS";
const LINK_TTL_DAYS = 30;
const MAX_PHONE_ATTEMPTS = 5;
const ALLOWED_STATUS = new Set(["APROVADO", "REPROVADO"]);
const CODE_PATTERN = /^[A-Za-z0-9_-]{16}$/;

const ALLOWED_ORIGINS = new Set([
  "https://orcamentofacil-lite.web.app",
  "https://orcamentofacil-lite.firebaseapp.com",
  "http://localhost:5000",
  "http://localhost:3000",
]);

const onlyDigits = (v) => String(v || "").replace(/\D/g, "");

/** 12 bytes aleatórios → 16 caracteres base64url (96 bits, não adivinhável). */
const newCode = () => crypto.randomBytes(12).toString("base64url");

/** Converte valores do Admin SDK para JSON plano (igual ao que a Web já lia). */
function plain(value) {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(plain);
  if (value && typeof value === "object" && value.constructor === Object) {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = plain(v);
    return out;
  }
  if (value && typeof value.path === "string" && value.firestore) return value.path;
  return value;
}

function applyCors(req, res) {
  const origin = req.get("origin");
  if (origin && ALLOWED_ORIGINS.has(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
    res.set("Vary", "Origin");
  }
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Firebase-AppCheck");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }
  if (req.method !== "POST") {
    res.status(405).json({ ok: false, error: "method" });
    return true;
  }
  return false;
}

function budgetRef(db, ownerUid, budgetId) {
  return db.doc(`EMPRESAS/${ownerUid}/USERS/${ownerUid}/ORCAMENTOS/${budgetId}`);
}

/**
 * Carrega o link e valida código, validade, bloqueio e telefone.
 * Retorna `{ link }` ou `{ status, error }` para responder ao cliente.
 */
async function loadAndCheck(db, code, phone) {
  if (!CODE_PATTERN.test(code)) return { status: 404, error: "invalid" };
  const ref = db.collection(COLLECTION).doc(code);
  const snap = await ref.get();
  if (!snap.exists) return { status: 404, error: "invalid" };
  const link = snap.data();

  if (link.revoked) return { status: 410, error: "revoked" };
  if (link.expiresAt && link.expiresAt.toMillis() < Date.now()) {
    return { status: 410, error: "expired" };
  }
  if ((link.failedAttempts || 0) >= MAX_PHONE_ATTEMPTS) {
    return { status: 429, error: "locked" };
  }

  const budgetSnap = await budgetRef(db, link.ownerUid, link.budgetId).get();
  if (!budgetSnap.exists) return { status: 404, error: "invalid" };

  const expected = onlyDigits(budgetSnap.get("FONE"));
  const given = onlyDigits(phone);
  const match =
    expected.length > 0 &&
    given.length > 0 &&
    crypto.timingSafeEqual(
      crypto.createHash("sha256").update(expected).digest(),
      crypto.createHash("sha256").update(given).digest()
    );

  if (!match) {
    await ref.update({ failedAttempts: FieldValue.increment(1) });
    const left = MAX_PHONE_ATTEMPTS - (link.failedAttempts || 0) - 1;
    return { status: 403, error: left > 0 ? "phone" : "locked", attemptsLeft: Math.max(left, 0) };
  }

  if (link.failedAttempts) await ref.update({ failedAttempts: 0 });
  return { link, budgetSnap };
}

function registerShareLinkFunctions(exports, region) {
  const db = getFirestore();

  // -------------------------------------------------------------------------
  // App do dono: cria o link curto. Exige login + App Check.
  // -------------------------------------------------------------------------
  exports.createShareLink = onRequest({ region }, async (req, res) => {
    if (applyCors(req, res)) return;
    try {
      const idToken = String(req.get("authorization") || "").replace(/^Bearer\s+/i, "");
      const appCheckToken = String(req.get("x-firebase-appcheck") || "");
      if (!idToken || !appCheckToken) {
        res.status(401).json({ ok: false, error: "unauthenticated" });
        return;
      }
      let uid;
      try {
        await getAppCheck().verifyToken(appCheckToken);
        uid = (await getAuth().verifyIdToken(idToken)).uid;
      } catch (_) {
        res.status(401).json({ ok: false, error: "unauthenticated" });
        return;
      }

      const budgetId = String(req.body?.budgetId || "").trim();
      if (!budgetId || budgetId.includes("/")) {
        res.status(400).json({ ok: false, error: "budgetId" });
        return;
      }
      const budget = await budgetRef(db, uid, budgetId).get();
      if (!budget.exists) {
        res.status(404).json({ ok: false, error: "notFound" });
        return;
      }

      const code = newCode();
      await db.collection(COLLECTION).doc(code).set({
        ownerUid: uid,
        budgetId,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt: Timestamp.fromMillis(Date.now() + LINK_TTL_DAYS * 86400000),
        revoked: false,
        failedAttempts: 0,
      });
      res.status(200).json({ ok: true, code });
    } catch (e) {
      logger.error("[createShareLink] erro", { error: String(e) });
      res.status(500).json({ ok: false, error: "internal" });
    }
  });

  // -------------------------------------------------------------------------
  // Web pública: valida o telefone e devolve SÓ aquele orçamento.
  // -------------------------------------------------------------------------
  exports.openShareLink = onRequest({ region }, async (req, res) => {
    if (applyCors(req, res)) return;
    try {
      const code = String(req.body?.code || "");
      const check = await loadAndCheck(db, code, req.body?.phone);
      if (check.error) {
        res.status(check.status).json({ ok: false, error: check.error, attemptsLeft: check.attemptsLeft });
        return;
      }
      const { link, budgetSnap } = check;
      const base = `EMPRESAS/${link.ownerUid}/USERS/${link.ownerUid}`;
      const [items, observations, owner] = await Promise.all([
        budgetSnap.ref.collection("ITENS").orderBy("CATEGORIA").get(),
        budgetSnap.ref.collection("OBSERVACAO").get(),
        db.doc(`${base}/INFOPDF/INFORMATION`).get(),
      ]);

      res.status(200).json({
        ok: true,
        budgetId: link.budgetId,
        budget: plain(budgetSnap.data()),
        items: items.docs.map((d) => ({ id: d.id, ...plain(d.data()) })),
        observations: observations.docs.map((d) => plain(d.data())),
        owner: plain(owner.data() || {}),
      });
    } catch (e) {
      logger.error("[openShareLink] erro", { error: String(e) });
      res.status(500).json({ ok: false, error: "internal" });
    }
  });

  // -------------------------------------------------------------------------
  // Web pública: aprova/reprova. Só altera STATUS + cria a notificação.
  // -------------------------------------------------------------------------
  exports.respondShareLink = onRequest({ region }, async (req, res) => {
    if (applyCors(req, res)) return;
    try {
      const status = String(req.body?.status || "").toUpperCase();
      if (!ALLOWED_STATUS.has(status)) {
        res.status(400).json({ ok: false, error: "status" });
        return;
      }
      const check = await loadAndCheck(db, String(req.body?.code || ""), req.body?.phone);
      if (check.error) {
        res.status(check.status).json({ ok: false, error: check.error, attemptsLeft: check.attemptsLeft });
        return;
      }
      const { link, budgetSnap } = check;
      const title = String(req.body?.title || "Orçamento").slice(0, 120);
      const message = String(req.body?.message || "").slice(0, 300);

      await budgetSnap.ref.update({ STATUS: status });
      // O trigger onBudgetApprovalNotification envia o push ao dono.
      await db
        .collection(`EMPRESAS/${link.ownerUid}/USERS/${link.ownerUid}/NOTIFICACOES`)
        .add({
          TITULO: title,
          MENSAGEM: message,
          STATUS: status,
          ORCAMENTO_ID: link.budgetId,
          CRIADO_EM: FieldValue.serverTimestamp(),
          LIDO: false,
        });
      res.status(200).json({ ok: true, status });
    } catch (e) {
      logger.error("[respondShareLink] erro", { error: String(e) });
      res.status(500).json({ ok: false, error: "internal" });
    }
  });
}

module.exports = { registerShareLinkFunctions };
