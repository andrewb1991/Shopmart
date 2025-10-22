# Configurazione API Ricette - Spoonacular

Questa applicazione utilizza l'API di Spoonacular per suggerire ricette basate sugli ingredienti in scadenza.

## Setup

### 1. Registrazione Spoonacular

1. Vai su [Spoonacular API Console](https://spoonacular.com/food-api/console#Dashboard)
2. Crea un account gratuito
3. Accedi alla dashboard e copia la tua API key

### 2. Configurazione Backend

1. Apri il file `.env` nella root del progetto backend
2. Aggiungi la tua API key:

```env
SPOONACULAR_API_KEY=la_tua_api_key_qui
```

### 3. Limiti Piano Gratuito

Il piano gratuito di Spoonacular offre:
- **150 richieste al giorno**
- Accesso a tutti gli endpoint
- Database completo di ricette

## Utilizzo nell'App

### Schermata "In Scadenza"

1. Tocca il pulsante **"Genera Ricetta"**
2. Seleziona i prodotti in scadenza che vuoi utilizzare (appariranno le checkbox)
3. Tocca **"Crea ricetta (N)"** in fondo alla schermata
4. L'app chiamerà l'API e mostrerà le ricette suggerite

## Endpoint Backend

### POST /api/recipes/suggest

Suggerisce ricette basate sugli ingredienti forniti.

**Body:**
```json
{
  "ingredients": ["pomodoro", "mozzarella", "basilico"]
}
```

**Response:**
```json
{
  "success": true,
  "recipes": [
    {
      "id": 123456,
      "title": "Pizza Margherita",
      "image": "https://...",
      "usedIngredientCount": 3,
      "missedIngredientCount": 2,
      "usedIngredients": ["pomodoro", "mozzarella", "basilico"],
      "missedIngredients": ["farina", "lievito"]
    }
  ]
}
```

### GET /api/recipes/:id

Ottiene i dettagli completi di una ricetta specifica.

**Response:**
```json
{
  "success": true,
  "recipe": {
    "id": 123456,
    "title": "Pizza Margherita",
    "image": "https://...",
    "servings": 4,
    "readyInMinutes": 30,
    "sourceUrl": "https://...",
    "summary": "...",
    "instructions": "...",
    "extendedIngredients": [...]
  }
}
```

## Note

- Se l'API key non è configurata, riceverai un errore 500 con il messaggio: "API key non configurata"
- Monitora il tuo utilizzo nella dashboard di Spoonacular per non superare il limite giornaliero
- Il parametro `language: 'it'` viene passato all'API, ma la disponibilità di ricette in italiano dipende dal database di Spoonacular

## Alternative Gratuite

Se hai bisogno di più richieste o preferisci altre API:

1. **Edamam Recipe API** - 10 req/min (tier gratuito limitato)
2. **TheMealDB API** - Completamente gratuita (database più limitato)

Per cambiare API, modifica gli endpoint in `server.js` alle linee 351-470.
