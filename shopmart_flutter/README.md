# Shopmart Flutter - App Magazzino Casa

App mobile Flutter per la gestione del magazzino domestico con scansione barcode tramite fotocamera.

## Funzionalità

- **Scansione Codice a Barre**: Scansiona i codici a barre dei prodotti usando la fotocamera del dispositivo
- **Ricerca Prodotti**: Cerca automaticamente le informazioni del prodotto tramite API
- **Gestione Inventario**: Visualizza tutti i prodotti nel magazzino con date di scadenza
- **Notifiche Scadenza**: Sistema di colori per identificare prodotti in scadenza o scaduti
- **Dettagli Prodotto**: Visualizza ingredienti, informazioni nutrizionali e immagini
- **Layout Responsive**: Interfaccia ottimizzata per telefoni e tablet

## Requisiti

- Flutter SDK 3.5.3 o superiore
- Dart SDK
- Backend Shopmart in esecuzione (vedi `../shopmart-be`)

## Installazione

1. Clona il repository e naviga nella directory del progetto:
```bash
cd shopmart_flutter
```

2. Installa le dipendenze:
```bash
flutter pub get
```

3. Configura l'URL del backend nel file `.env`:
```env
API_URL=http://localhost:5001/api
```

**Nota**: Per testare su dispositivi fisici, sostituisci `localhost` con l'indirizzo IP del tuo computer:
```env
API_URL=http://192.168.1.XXX:5001/api
```

4. Avvia l'app:
```bash
flutter run
```

## Struttura del Progetto

```
lib/
├── main.dart                    # Entry point dell'app
├── models/                      # Modelli dati
│   ├── product.dart            # Modello Prodotto
│   └── inventory_item.dart     # Modello Item Inventario
├── services/                    # Servizi API
│   └── api_service.dart        # Chiamate HTTP al backend
├── providers/                   # State management
│   └── inventory_provider.dart # Provider gestione inventario
├── screens/                     # Schermate
│   ├── home_screen.dart        # Schermata principale
│   └── barcode_scanner_screen.dart # Scanner barcode
└── widgets/                     # Widget riutilizzabili
    └── add_product_widget.dart # Widget aggiunta prodotto
```

## Dipendenze Principali

- `mobile_scanner`: Scansione barcode con fotocamera
- `http`: Chiamate API REST
- `provider`: State management
- `intl`: Formattazione date e localizzazione
- `flutter_dotenv`: Gestione variabili ambiente

## Permessi

### Android
I permessi per la fotocamera sono configurati in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.CAMERA`
- `android.hardware.camera`
- `android.hardware.camera.autofocus`

### iOS
Il permesso per la fotocamera è configurato in `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`

## Come Usare

1. **Scansiona un Prodotto**:
   - Premi il pulsante "Scansiona Codice a Barre"
   - Inquadra il codice a barre del prodotto
   - L'app cercherà automaticamente le informazioni

2. **Aggiungi al Magazzino**:
   - Dopo la scansione, inserisci la quantità
   - Seleziona la data di scadenza
   - Premi "Aggiungi al magazzino"

3. **Visualizza Inventario**:
   - Tutti i prodotti sono mostrati con indicatori di stato colorati:
     - 🟢 Verde: Prodotto OK
     - 🟡 Giallo: Attenzione (vicino alla scadenza)
     - 🟠 Arancione: Urgente
     - 🔴 Rosso: Scaduto

4. **Elimina Prodotto**:
   - Premi l'icona del cestino sul prodotto
   - Conferma l'eliminazione

## Build per Produzione

### Android
```bash
flutter build apk --release
# oppure per app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Note di Sviluppo

- L'app usa il pattern Provider per la gestione dello stato
- Le chiamate API sono gestite tramite il servizio `ApiService`
- La scansione barcode usa `mobile_scanner` che supporta vari formati di codici a barre
- Le date sono formattate in italiano usando il pacchetto `intl`

## Troubleshooting

### Errore di connessione al backend
- Verifica che il backend sia in esecuzione
- Controlla l'URL nel file `.env`
- Su dispositivi fisici, usa l'IP del computer invece di localhost

### Fotocamera non funziona
- Verifica che i permessi siano configurati correttamente
- Su iOS, controlla che la descrizione dell'uso della fotocamera sia presente in Info.plist
- Su Android, verifica che i permessi siano in AndroidManifest.xml

### Errore dipendenze
```bash
flutter clean
flutter pub get
```

## Licenza

Questo progetto fa parte del sistema Shopmart per la gestione del magazzino domestico.
