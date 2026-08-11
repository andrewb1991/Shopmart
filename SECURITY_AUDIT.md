# 🔒 Security Audit — Shopmart

**Scope:** backend `shopmart-be/server.js` (API Express su Railway), client
`shopmart_flutter/` (mobile + web su Firebase), configurazione di deploy e
gestione segreti.
**Data:** 2026-08-11
**Metodo:** review statica del codice + verifica dinamica (endpoint live, APK,
git history).

---

## Executive summary

L'app è funzionalmente ricca ma presenta **un difetto di autenticazione
critico** che consente il takeover di qualsiasi account, oltre a mancanze
sistemiche di hardening (no rate limiting, no validazione input, endpoint a
pagamento aperti).

Note positive verificate sul campo:
- **Nessun segreto è mai finito nella git history.**
- **L'`.env` NON è servito da Firebase** (la regola `ignore` dei dotfile in
  `firebase.json` lo blocca: `/assets/.env` restituisce l'index.html, non il
  file). Il segreto resta però estraibile dall'APK.

Il rischio maggiore è quindi lato **logica di autenticazione** e **segreti
inclusi nell'APK**.

---

## Riepilogo findings

| #   | Severità     | Area      | Problema |
|-----|--------------|-----------|----------|
| C1  | 🔴 CRITICO   | Auth      | Google Sign-In **non verificato** lato server → account takeover |
| H1  | 🟠 Alto      | Auth      | `JWT_SECRET` con fallback debole hardcoded; token 30gg non revocabili |
| H2  | 🟠 Alto      | Auth      | Nessun **rate limiting** / anti brute-force su login/register/google |
| H3  | 🟠 Alto      | Abuso     | Endpoint verso **API a pagamento** (DeepL/Spoonacular) aperti senza auth |
| H4  | 🟠 Alto      | Segreti   | `DEEPL_API_KEY` **inclusa nell'APK** (e inutile lato client) |
| M1  | 🟡 Medio     | Input     | Nessuna validazione input → superficie **NoSQL injection**, password deboli |
| M2  | 🟡 Medio     | Hardening | Header di sicurezza assenti (no `helmet`) |
| M3  | 🟡 Medio     | Info leak | Dettagli errori upstream restituiti al client; log verbosi |
| M4  | 🟡 Medio     | Segreti   | Credenziali reali nei `.env` locali; DB user non a privilegi minimi |
| L1  | ⚪ Basso     | Client    | Token su web in localStorage (esposizione via XSS) |
| L2  | ⚪ Basso     | Gap       | `/api/auth/profile` chiamato dal client ma assente nel server |
| L3  | ⚪ Basso     | DoS       | `express.json` senza limite esplicito; nessun timeout richieste |
| L4  | ⚪ Basso     | Governance| Nessun `npm audit` / CI / scansione dipendenze |

---

## Dettaglio findings principali

### 🔴 C1 — Account takeover via `/api/auth/google`
`server.js:170-231` si fida ciecamente di `googleId` ed `email` dal body e
**non verifica l'`idToken`**. Il client lo invia (`auth_service.dart:127`) ma il
server lo ignora. Con `findOne({ $or: [{googleId},{email}] })`:

```
POST /api/auth/google   { "googleId": "qualsiasi", "email": "vittima@gmail.com" }
→ 200 + JWT valido 30 giorni per l'account della vittima
```

**Impatto:** compromissione totale di qualunque account (anche registrato con
password).
**Fix (funzionalità invariata):** verificare l'`idToken` server-side con
`google-auth-library` (`OAuth2Client.verifyIdToken`), fidarsi solo di
`email`/`sub` restituiti da Google, ignorare i campi del body.

### 🟠 H1 — Gestione JWT
`server.js:16`: `JWT_SECRET = process.env.JWT_SECRET || 'shopmart_secret_key_change_in_production'`.
Se la env manca, i token sono firmati con un segreto noto → forgiabili.
`expiresIn: '30d'` senza revoca.
**Fix:** rimuovere il fallback (fail-fast); secret forte solo su Railway;
opzionale access token breve + refresh token.

### 🟠 H2 — Nessun rate limiting su auth
`/api/auth/login|register|google` non hanno limiti → brute force / credential
stuffing. **Fix:** `express-rate-limit` + lockout progressivo.

### 🟠 H3 — Endpoint a pagamento aperti (abuso economico)
Pubblici e senza rate limit: `translate-*` verso DeepL (`server.js:846,927,1016`)
e `recipes/search`/`recipes/:id`/`product/lookup` verso Spoonacular/OpenFoodFacts
(`server.js:432,777,350`). **Fix:** auth dove sensato + rate limit + caching.

### 🟠 H4 — Segreto nell'APK
`assets/flutter_assets/.env` è dentro l'APK e contiene `DEEPL_API_KEY`, estraibile
e inutile lato client (traduzione lato backend). **Fix:** rimuovere la chiave dai
`.env` del client, togliere `.env` dagli `assets` in `pubspec.yaml:112-113`,
rigenerare la chiave DeepL.

### 🟡 M1 — Validazione input / NoSQL injection
`email`/`password` finiscono nelle query Mongoose senza controllo di tipo
(`server.js:147,160`); `email` come oggetto (`{"$gt":""}`) altera la query.
Nessuna policy password. **Fix:** `express-validator`/`zod`, forzare stringhe,
lunghezza minima password.

### 🟡 M2/M3/M4 — Hardening
- **M2:** aggiungere `helmet` (HSTS, X-Content-Type-Options, ecc.).
- **M3:** non restituire `err.response.data` al client (`server.js:426,468-471`);
  log meno verbosi.
- **M4:** DB user a privilegi minimi + IP allowlist su Atlas; secret manager;
  rotazione delle credenziali eventualmente esposte.

### ⚪ L1-L4
- **L1:** token su web in localStorage → esposto a XSS. Accettabile ma da notare.
- **L2:** `/api/auth/profile` (PUT) chiamato dal client (`auth_service.dart:274`)
  ma **assente** nel server → cambio password già non funzionante.
- **L3:** limite payload e timeout richieste da impostare.
- **L4:** `npm audit`/Dependabot + check di sicurezza in CI.

---

## 📋 Piano di remediation (a funzionalità invariata)

### Fase 0 — Emergenza (oggi)
1. **Rigenerare la `DEEPL_API_KEY`** (è nell'APK); tenerla solo nelle env di Railway.
2. Verificare su Railway: `JWT_SECRET` forte, `MONGODB_URI`, `ALLOWED_ORIGINS`,
   `GOOGLE_CLIENT_ID`. Rimuovere il fallback debole nel codice (H1).
3. (Opz.) ruotare `JWT_SECRET` → invalida eventuali token forgiati.

### Fase 1 — Fix critici auth (1-2 giorni)
4. **C1:** verifica `idToken` Google server-side.
5. **H2:** rate limiting su `/api/auth/*` + lockout.
6. **M1:** validazione input + policy password.

### Fase 2 — Hardening (settimana)
7. **H3:** auth + rate limit + cache sugli endpoint costosi.
8. **H4:** pulizia segreti dal client.
9. **M2** `helmet`, **M3** sanitizzazione errori/log.

### Fase 3 — Governance
10. `npm audit`/Dependabot, secret manager, logging senza PII, ripristino
    endpoint `/api/auth/profile`, check di sicurezza in CI.

Nessuna delle correzioni rimuove funzionalità: sono aggiunte difensive o
irrobustimenti dei flussi esistenti.

---

## Stato remediation

| Fase | Item | Stato |
|------|------|-------|
| 0 | Rimozione fallback debole `JWT_SECRET` (H1) | ✅ fatto e deployato |
| 0 | Rigenerazione `DEEPL_API_KEY` + env Railway | ☐ azione manuale |
| 1 | C1 — verifica `idToken` Google | ✅ fatto e deployato (Railway) |
| 1 | Login Google web via pulsante GIS (fallout C1) | ✅ fatto e deployato (Firebase) |
| 1 | H2 — rate limiting | ✅ fatto e deployato |
| 1 | M1 — validazione input + policy password | ✅ fatto e deployato |
| 2 | H3 — rate limit endpoint costosi | ✅ fatto |
| 2 | H4 — rimozione DEEPL_API_KEY dal client | ✅ fatto (rotazione chiave = manuale) |
| 2 | M2 — helmet (security headers) | ✅ fatto |
| 2 | M3 — no leak errori upstream al client | ✅ fatto |
| 3 | `npm audit` backend → **0 vulnerabilità** (erano 9) | ✅ fatto |
| 3 | Ripristino endpoint `/api/auth/profile` (L2) | ✅ fatto |
| 3 | CI GitHub Actions (test + audit ad ogni push) | ✅ fatto |
