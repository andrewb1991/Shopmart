// Test unitari per la validazione delle credenziali (fix M1).
const test = require('node:test');
const assert = require('node:assert');
const { validateCredentials } = require('../auth/validators');

test('accetta credenziali valide (login)', () => {
  assert.strictEqual(validateCredentials({ email: 'a@b.com', password: 'secret1' }).ok, true);
});

test('rifiuta email non valida', () => {
  assert.strictEqual(validateCredentials({ email: 'nope', password: 'secret12' }).ok, false);
});

test('rifiuta email non-stringa (difesa NoSQL injection)', () => {
  assert.strictEqual(validateCredentials({ email: { $gt: '' }, password: 'secret12' }).ok, false);
});

test('rifiuta password mancante o non-stringa', () => {
  assert.strictEqual(validateCredentials({ email: 'a@b.com', password: '' }).ok, false);
  assert.strictEqual(validateCredentials({ email: 'a@b.com', password: { $ne: null } }).ok, false);
});

test('login NON impone lunghezza minima (utenti esistenti)', () => {
  assert.strictEqual(validateCredentials({ email: 'a@b.com', password: 'short' }).ok, true);
});

test('registrazione impone password >= 8 caratteri', () => {
  assert.strictEqual(
    validateCredentials({ email: 'a@b.com', password: 'short' }, { enforcePasswordStrength: true }).ok,
    false,
  );
  assert.strictEqual(
    validateCredentials({ email: 'a@b.com', password: 'longenough' }, { enforcePasswordStrength: true }).ok,
    true,
  );
});
