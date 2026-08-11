// auth/validators.js
// Validazione input per le rotte di autenticazione (fix M1).
// Blocca anche input non-stringa: difesa contro NoSQL injection
// (es. email = { "$gt": "" } che altrimenti altererebbe la query Mongoose).

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD_LENGTH = 8;

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

function isValidEmail(v) {
  return typeof v === 'string' && v.length <= 254 && EMAIL_RE.test(v.trim());
}

/**
 * Valida email + password.
 * @param {object} input                     { email, password }
 * @param {object} opts
 * @param {boolean} opts.enforcePasswordStrength  true in registrazione (impone lunghezza minima)
 * @returns {{ok:true}|{ok:false, error:string}}
 */
function validateCredentials({ email, password } = {}, { enforcePasswordStrength = false } = {}) {
  if (!isValidEmail(email)) {
    return { ok: false, error: 'Email non valida' };
  }
  if (!isNonEmptyString(password)) {
    return { ok: false, error: 'Password obbligatoria' };
  }
  // In login NON imponiamo la lunghezza minima, per non escludere utenti esistenti.
  if (enforcePasswordStrength && password.length < MIN_PASSWORD_LENGTH) {
    return { ok: false, error: `La password deve avere almeno ${MIN_PASSWORD_LENGTH} caratteri` };
  }
  return { ok: true };
}

module.exports = { validateCredentials, isValidEmail, isNonEmptyString, MIN_PASSWORD_LENGTH };
