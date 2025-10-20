# Quick Start Guide - Shopmart Flutter

## Setup Rapido

### 1. Installa dipendenze
```bash
flutter pub get
```

### 2. Configura Backend
Assicurati che il backend sia in esecuzione:
```bash
cd ../shopmart-be
npm start
```

### 3. Configura URL API
Il file `.env` è già configurato con:
```
API_URL=http://localhost:5001/api
```

**IMPORTANTE per test su dispositivo fisico:**
- Trova l'IP del tuo computer: `ipconfig` (Windows) o `ifconfig` (Mac/Linux)
- Modifica `.env` con l'IP: `API_URL=http://192.168.1.XXX:5001/api`

### 4. Avvia l'app
```bash
flutter run
```

## Test Rapido Funzionalità

1. **Test Scanner**:
   - Premi "Scansiona Codice a Barre"
   - Inquadra un barcode (es. su un prodotto alimentare)
   - L'app cerca il prodotto automaticamente

2. **Test Aggiunta Prodotto**:
   - Dopo la scansione, inserisci quantità
   - Seleziona data di scadenza
   - Premi "Aggiungi al magazzino"

3. **Test Inventario**:
   - Visualizza tutti i prodotti aggiunti
   - Controlla i colori di stato (verde/giallo/arancione/rosso)
   - Prova a eliminare un prodotto

## Comandi Utili

```bash
# Verifica problemi
flutter doctor

# Analizza codice
flutter analyze

# Pulizia build
flutter clean && flutter pub get

# Build Android
flutter build apk --release

# Lista dispositivi
flutter devices
```

## Struttura File Creati

```
lib/
├── main.dart                         # Entry point
├── models/
│   ├── product.dart                 # Modello prodotto
│   └── inventory_item.dart          # Modello item inventario
├── services/
│   └── api_service.dart             # Chiamate HTTP
├── providers/
│   └── inventory_provider.dart      # State management
├── screens/
│   ├── home_screen.dart             # Home con inventario
│   └── barcode_scanner_screen.dart  # Scanner fotocamera
└── widgets/
    └── add_product_widget.dart      # Widget aggiunta prodotto
```

## Permessi Configurati

✅ Android: Camera permission in `AndroidManifest.xml`
✅ iOS: Camera usage description in `Info.plist`

## Troubleshooting Veloce

**App non si connette al backend:**
- Verifica che il backend sia avviato
- Controlla l'URL in `.env`
- Su dispositivo fisico, usa IP invece di localhost

**Fotocamera non funziona:**
- Verifica permessi in AndroidManifest.xml / Info.plist
- Riavvia l'app dopo aver dato i permessi

**Errore dipendenze:**
```bash
flutter clean
flutter pub get
```

## Prossimi Passi

- Testa su diversi dispositivi (Android/iOS)
- Prova la scansione con vari tipi di barcode
- Verifica il layout responsive su tablet
- Testa le notifiche di scadenza con date diverse
