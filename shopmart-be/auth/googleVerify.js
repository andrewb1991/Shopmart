// auth/googleVerify.js
// Verifica server-side dell'idToken Google (fix C1 del security audit).
// Estratto in modulo dedicato per essere testabile via dependency injection
// del client OAuth2 (vedi test/googleVerify.test.js).
const { OAuth2Client } = require('google-auth-library');

/**
 * Verifica crittograficamente un idToken Google e restituisce SOLO i claim
 * fidati provenienti da Google. Il chiamante non deve mai fidarsi di email/
 * googleId forniti dal client: usare esclusivamente il risultato di questa
 * funzione.
 *
 * @param {string} idToken               ID token dal client Google Sign-In
 * @param {object} opts
 * @param {string} opts.clientId         GOOGLE_CLIENT_ID atteso come audience
 * @param {object} [opts.client]         istanza OAuth2Client (iniettabile per i test)
 * @returns {Promise<{googleId:string,email:string,emailVerified:boolean,displayName:?string,photoUrl:?string,firstName:?string,lastName:?string}>}
 * @throws {Error} con .code in ID_TOKEN_MISSING | SERVER_MISCONFIG | ID_TOKEN_INVALID | EMAIL_NOT_VERIFIED
 */
async function verifyGoogleIdToken(idToken, { clientId, client } = {}) {
  if (!idToken || typeof idToken !== 'string') {
    const e = new Error('idToken mancante o non valido');
    e.code = 'ID_TOKEN_MISSING';
    throw e;
  }
  if (!clientId) {
    const e = new Error('GOOGLE_CLIENT_ID non configurato sul server');
    e.code = 'SERVER_MISCONFIG';
    throw e;
  }

  const oauthClient = client || new OAuth2Client(clientId);
  // verifyIdToken valida firma, scadenza, issuer e audience: se qualcosa non
  // torna lancia un'eccezione, quindi un token forgiato viene rifiutato qui.
  const ticket = await oauthClient.verifyIdToken({ idToken, audience: clientId });
  const payload = ticket.getPayload();

  if (!payload || !payload.sub || !payload.email) {
    const e = new Error('Token Google privo dei claim richiesti');
    e.code = 'ID_TOKEN_INVALID';
    throw e;
  }
  if (payload.email_verified === false) {
    const e = new Error('Email Google non verificata');
    e.code = 'EMAIL_NOT_VERIFIED';
    throw e;
  }

  const firstName = payload.given_name
    || (payload.name ? payload.name.split(' ')[0] : null);
  const lastName = payload.family_name
    || (payload.name ? (payload.name.split(' ').slice(1).join(' ') || null) : null);

  return {
    googleId: payload.sub,
    email: payload.email,
    emailVerified: payload.email_verified !== false,
    displayName: payload.name || null,
    photoUrl: payload.picture || null,
    firstName,
    lastName,
  };
}

module.exports = { verifyGoogleIdToken };
