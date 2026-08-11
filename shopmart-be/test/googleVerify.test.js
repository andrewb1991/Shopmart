// Test unitari per la verifica dell'idToken Google (fix C1).
// Usa il test runner integrato di Node (`node --test`), nessuna dipendenza extra.
const test = require('node:test');
const assert = require('node:assert');
const { verifyGoogleIdToken } = require('../auth/googleVerify');

// Client OAuth2 finto, iniettabile: restituisce un payload controllato,
// oppure lancia per simulare una firma non valida.
function fakeClient(payload, { throwOnVerify = false } = {}) {
  return {
    verifyIdToken: async ({ idToken, audience }) => {
      if (throwOnVerify) throw new Error('Invalid token signature');
      return { getPayload: () => payload };
    },
  };
}

test('rifiuta idToken mancante', async () => {
  await assert.rejects(
    () => verifyGoogleIdToken(undefined, { clientId: 'cid' }),
    /idToken mancante/,
  );
});

test('rifiuta se GOOGLE_CLIENT_ID non è configurato sul server', async () => {
  await assert.rejects(
    () => verifyGoogleIdToken('tok', { clientId: undefined, client: fakeClient({}) }),
    /GOOGLE_CLIENT_ID/,
  );
});

test('rifiuta un token con firma non valida (forgiato)', async () => {
  await assert.rejects(
    () => verifyGoogleIdToken('forged', { clientId: 'cid', client: fakeClient({}, { throwOnVerify: true }) }),
    /Invalid token signature/,
  );
});

test('rifiuta un token senza i claim richiesti (sub/email)', async () => {
  const client = fakeClient({ sub: '123' }); // manca email
  await assert.rejects(
    () => verifyGoogleIdToken('tok', { clientId: 'cid', client }),
    /claim richiesti/,
  );
});

test('rifiuta email non verificata', async () => {
  const client = fakeClient({ sub: '123', email: 'a@b.com', email_verified: false });
  await assert.rejects(
    () => verifyGoogleIdToken('tok', { clientId: 'cid', client }),
    /non verificata/,
  );
});

test('restituisce i claim fidati per un token valido', async () => {
  const client = fakeClient({
    sub: '123', email: 'user@gmail.com', email_verified: true,
    name: 'Mario Rossi', picture: 'http://x/y.png',
  });
  const r = await verifyGoogleIdToken('tok', { clientId: 'cid', client });
  assert.strictEqual(r.googleId, '123');
  assert.strictEqual(r.email, 'user@gmail.com');
  assert.strictEqual(r.firstName, 'Mario');
  assert.strictEqual(r.lastName, 'Rossi');
  assert.strictEqual(r.emailVerified, true);
});

// Regressione di sicurezza (C1): l'identità deriva SOLO dal payload verificato.
test('usa esclusivamente il payload Google verificato', async () => {
  const client = fakeClient({ sub: 'realsub', email: 'real@gmail.com', email_verified: true });
  const r = await verifyGoogleIdToken('tok', { clientId: 'cid', client });
  assert.strictEqual(r.email, 'real@gmail.com');
  assert.strictEqual(r.googleId, 'realsub');
});
