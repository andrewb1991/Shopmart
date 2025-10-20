# 📦 Shopmart - Gestione Magazzino Casa

Sistema completo per la gestione dell'inventario domestico con scansione barcode e tracciamento scadenze.

## 🏗️ Struttura del Progetto

```
Shopmart/
├── shopmart-be/     # Backend Node.js + Express + MongoDB
└── shopmart-fe/     # Frontend React + TailwindCSS
```

## ✨ Funzionalità

- 🔍 **Ricerca prodotti** tramite barcode usando OpenFoodFacts API
- 📸 **Visualizzazione immagini** prodotti
- 🗓️ **Tracciamento scadenze** con sistema di alert
- 📊 **Inventario completo** con informazioni nutrizionali
- 🇮🇹 **Interfaccia in italiano** con dati localizzati
- 🎨 **UI moderna** con TailwindCSS

## 🚀 Setup

### Backend

```bash
cd shopmart-be
npm install
# Configura .env con MONGODB_URI e PORT
npm start
```

### Frontend

```bash
cd shopmart-fe
npm install
# Configura .env con REACT_APP_API_URL
npm start
```

## 🔧 Tecnologie

**Backend:**
- Node.js + Express
- MongoDB + Mongoose
- OpenFoodFacts API
- CORS

**Frontend:**
- React 18
- TailwindCSS
- Lucide Icons

## 📝 Variabili d'Ambiente

### Backend (.env)
```
MONGODB_URI=your_mongodb_connection_string
PORT=5001
```

### Frontend (.env)
```
REACT_APP_API_URL=http://localhost:5001/api
```

## 🧪 Test con Barcode

Prova questi barcode per testare l'app:
- `8000500037560` - Kinder Bueno
- `3017620422003` - Nutella
- `5449000000996` - Coca Cola

## 📄 Licenza

MIT
