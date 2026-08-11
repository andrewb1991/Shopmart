# 📦 Shopmart — Panoramica progetto, debug e deploy

> Documento ricostruito dal codice reale. Il `README.md` di root è obsoleto:
> non menziona l'app Flutter, che è il **client principale**.

## 🗂️ Struttura del progetto

Monorepo (`origin`: `github.com/andrewb1991/Shopmart`) con tre sottoprogetti
**indipendenti**, nessun `package.json` di root:

| Progetto          | Stack                                                        | Ruolo                          |
|-------------------|--------------------------------------------------------------|--------------------------------|
| `shopmart-be/`    | Node.js + **Express 5**, MongoDB/Mongoose, JWT, bcrypt       | Backend API (porta **5001**)   |
| `shopmart_flutter/` | Flutter (Dart SDK ^3.5.3)                                  | **Client principale** (mobile + web) |
| `shopmart-fe/`    | React 19 + react-scripts                                     | Frontend web legacy (CRA)      |

Il backend usa OpenFoodFacts (barcode), Spoonacular (ricette) e
DeepL/google-translate per le traduzioni. Auth via JWT.
Esistono anche `server_patch/server.js` e `shopmart-be/old_server.js` come
versioni alternative/backup.

**Nessuna CI** (`.github/workflows` assente) → i deploy sono manuali.

## 🐛 Avvio in debug

### 1. Backend (necessario per tutto il resto)
```bash
cd shopmart-be
npm install
npm run dev      # nodemon (hot reload) — oppure: npm start
```
Gira su `http://localhost:5001`, legge le env da `shopmart-be/.env`
(`MONGODB_URI`, `PORT`, `JWT_SECRET`, `SPOONACULAR_API_KEY`, `DEEPL_API_KEY`).

### 2. App Flutter (client principale)
```bash
cd shopmart_flutter
flutter pub get
flutter run                          # device/emulatore in lista
```
La base URL è gestita da `lib/utils/app_config.dart`: in **debug** punta a
`http://localhost:5001`, in **release** a `https://shopmart-be.up.railway.app`.
Override via `.env`/`.env.local` (`API_BASE_URL` o `API_URL`, caricate da
`flutter_dotenv`).

> ⚠️ Su **dispositivo fisico** `localhost` non funziona: usa l'IP del Mac,
> es. `API_URL=http://192.168.1.XXX:5001/api`.

### 3. Frontend React (legacy, se serve)
```bash
cd shopmart-fe
npm install
npm start        # http://localhost:3000, API via REACT_APP_API_URL
```

## 🔥 Deploy su Firebase (web Flutter)

Configurato in `shopmart_flutter/firebase.json` (public = `build/web`, SPA
rewrite) e `.firebaserc` → progetto **`shopmart-app-ceb98`**.

```bash
cd shopmart_flutter
flutter build web --release          # genera build/web
firebase deploy --only hosting       # pubblica su shopmart-app-ceb98.web.app
```
URL risultanti: `https://shopmart-app-ceb98.web.app` e `.firebaseapp.com`.
In release il build punta automaticamente al backend Railway.

## 🚂 Deploy su Railway (backend)

Backend live su **`https://shopmart-be.up.railway.app`**. Non ci sono file di
config Railway (né `railway.json` / `Procfile` / `nixpacks`) → Railway rileva
Node ed esegue `npm start` (`server.js`, `PORT = process.env.PORT || 5001`).

Con il servizio connesso al repo GitHub il deploy tipicamente parte **al push**
sul branch tracciato:
```bash
git push origin main     # → Railway builda e rilascia automaticamente
```
In alternativa via CLI: `railway up` (dalla cartella `shopmart-be`).

**Env da impostare nel dashboard Railway** (non nel `.env`, che è gitignored):
`MONGODB_URI`, `JWT_SECRET`, `SPOONACULAR_API_KEY`, `DEEPL_API_KEY`, e
soprattutto `ALLOWED_ORIGINS` per il CORS:
```
ALLOWED_ORIGINS=https://shopmart-app-ceb98.web.app,https://shopmart-app-ceb98.firebaseapp.com
```
`PORT` lo inietta Railway, non va forzato.

## ⚠️ Nota sicurezza

`shopmart-be/.env` contiene **credenziali reali e attive** (password MongoDB
Atlas, JWT secret, API key Spoonacular/DeepL). Il file è ora gitignored e c'è
il commit che lo rimuove dal tracking — ma se era stato committato in passato
**resta nella git history** ed è da considerare compromesso.

- Ruotare le credenziali (password Atlas, JWT secret, API key).
- Tenerle solo nei secret di Railway / Firebase, mai nel repo.
