// server.js - Backend Express.js
const express = require('express');
const axios = require('axios');
const mongoose = require('mongoose');
const crypto = require('crypto');
require('dotenv').config();

// Funzione per generare UUID
const uuidv4 = () => crypto.randomUUID();

const app = express();

// CORS middleware - DEVE essere il primo middleware
app.use((req, res, next) => {
  // Log per debug
  console.log(`${req.method} ${req.path}`);

  res.header('Access-Control-Allow-Origin', 'http://localhost:3000');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Access-Control-Allow-Credentials', 'true');

  // Gestisci preflight request
  if (req.method === 'OPTIONS') {
    console.log('✓ OPTIONS request handled');
    return res.status(200).end();
  }

  next();
});

app.use(express.json());

// ============================================
// MONGODB CONNECTION
// ============================================
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/warehouse';

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✓ MongoDB connesso'))
.catch((err) => console.error('✗ Errore MongoDB:', err.message));

// ============================================
// MONGOOSE SCHEMA E MODELLO
// ============================================
const productSchema = new mongoose.Schema({
  id: { type: String, default: () => uuidv4() },
  barcode: { type: String, required: true },
  productName: { type: String, required: true },
  brand: { type: String },
  category: { type: String },
  quantity: { type: Number, required: true },
  unit: { type: String, default: 'pz' },
  expiryDate: { type: Date, required: true },
  dateAdded: { type: Date, default: Date.now },
  ingredients: { type: String },
  nutritionInfo: {
    energy: Number,
    protein: Number,
    fat: Number,
    carbs: Number,
    salt: Number,
  },
  imageUrl: { type: String },
  suggestions: [String],
  userId: { type: String }, // Per future features multi-utente
}, { timestamps: true });

const Product = mongoose.model('Product', productSchema);

// ============================================
// MODELLO PRODOTTO
// ============================================
// {
//   id: uuid,
//   barcode: "123456789",
//   productName: "Latte intero",
//   brand: "Parmalat",
//   category: "Dairy",
//   quantity: 2,
//   unit: "L",
//   expiryDate: "2025-12-20",
//   dateAdded: "2025-10-20",
//   nutritionInfo: {...},
//   ingredients: "...",
//   imageUrl: "...",
//   suggestions: [...]
// }

// ============================================
// ENDPOINT 1: Lookup prodotto da OpenFoodFacts
// ============================================
app.post('/api/product/lookup', async (req, res) => {
  try {
    const { barcode } = req.body;

    if (!barcode) {
      return res.status(400).json({ error: 'Barcode richiesto' });
    }

    // Chiama OpenFoodFacts API con lingua italiana
    const response = await axios.get(
      `https://world.openfoodfacts.org/api/v2/product/${barcode}?fields=code,product_name,product_name_it,brands,categories,categories_tags,ingredients_text,ingredients_text_it,nutriments,image_front_url,quantity&lc=it`
    );

    if (response.data.status === 0 || !response.data.product) {
      return res.status(404).json({ error: 'Prodotto non trovato' });
    }

    const product = response.data.product;

    // Estrai categoria in italiano dai tags
    let categoryIT = 'N/A';
    if (product.categories_tags && product.categories_tags.length > 0) {
      // I tag hanno formato "it:nome-categoria" o "en:nome-categoria"
      const itTag = product.categories_tags.find(tag => tag.startsWith('it:'));
      if (itTag) {
        categoryIT = itTag.replace('it:', '').replace(/-/g, ' ');
        // Capitalizza la prima lettera
        categoryIT = categoryIT.charAt(0).toUpperCase() + categoryIT.slice(1);
      } else {
        // Se non c'è tag italiano, usa il primo disponibile
        categoryIT = product.categories_tags[0].replace(/^[a-z]{2}:/, '').replace(/-/g, ' ');
        categoryIT = categoryIT.charAt(0).toUpperCase() + categoryIT.slice(1);
      }
    } else if (product.categories) {
      // Fallback: usa la prima categoria dalla stringa
      categoryIT = product.categories.split(',')[0].trim();
    }

    // Estrai dati rilevanti (priorità alla lingua italiana)
    const productData = {
      barcode: product.code || barcode,
      productName: product.product_name_it || product.product_name || 'Sconosciuto',
      brand: product.brands || 'N/A',
      category: categoryIT,
      ingredients: product.ingredients_text_it || product.ingredients_text || 'Non disponibili',
      nutritionInfo: {
        energy: product.nutriments?.energy_100g || product.nutriments?.['energy-kcal_100g'],
        protein: product.nutriments?.proteins_100g,
        fat: product.nutriments?.fat_100g,
        carbs: product.nutriments?.carbohydrates_100g,
        salt: product.nutriments?.salt_100g,
      },
      imageUrl: product.image_front_url || null,
      quantity: 1,
      unit: product.quantity || 'pz',
    };

    // Recupera suggerimenti di utilizzo basati su categoria
    const suggestions = await getSuggestions(productData.category);

    res.json({ success: true, product: productData, suggestions });
  } catch (error) {
    console.error('Errore lookup:', error.message);
    res.status(500).json({ error: 'Errore nella ricerca del prodotto' });
  }
});

// ============================================
// ENDPOINT 2: Aggiungi prodotto al magazzino
// ============================================
app.post('/api/inventory/add', async (req, res) => {
  try {
    const { barcode, productName, brand, category, quantity, unit, expiryDate, ingredients, nutritionInfo, imageUrl, suggestions } = req.body;

    if (!barcode || !productName || !expiryDate) {
      return res.status(400).json({ error: 'Campi obbligatori mancanti' });
    }

    const newProduct = new Product({
      barcode,
      productName,
      brand,
      category,
      quantity,
      unit: unit || 'pz',
      expiryDate: new Date(expiryDate),
      ingredients,
      nutritionInfo,
      imageUrl,
      suggestions: suggestions || [],
    });

    await newProduct.save();

    res.json({ success: true, product: newProduct, message: 'Prodotto aggiunto' });
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ error: 'Errore nell\'aggiunta del prodotto' });
  }
});

// ============================================
// ENDPOINT 3: Ottieni inventario
// ============================================
app.get('/api/inventory', async (req, res) => {
  try {
    const products = await Product.find();

    // Calcola giorni a scadenza per ogni prodotto
    const inventoryWithStatus = products.map((product) => {
      const expiryDate = new Date(product.expiryDate);
      const today = new Date();
      const daysLeft = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));

      let status = 'OK';
      if (daysLeft <= 0) status = 'SCADUTO';
      else if (daysLeft <= 3) status = 'URGENTE';
      else if (daysLeft <= 7) status = 'ATTENZIONE';

      return { 
        ...product.toObject(), 
        daysLeft, 
        status 
      };
    });

    // Ordina per urgenza
    const sorted = inventoryWithStatus.sort((a, b) => a.daysLeft - b.daysLeft);

    res.json({ success: true, products: sorted });
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ error: 'Errore nel recupero inventario' });
  }
});

// ============================================
// ENDPOINT 4: Aggiorna quantità prodotto
// ============================================
app.put('/api/inventory/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;

    const product = await Product.findByIdAndUpdate(
      id,
      { quantity },
      { new: true }
    );

    if (!product) {
      return res.status(404).json({ error: 'Prodotto non trovato' });
    }

    res.json({ success: true, product, message: 'Quantità aggiornata' });
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ error: 'Errore nell\'aggiornamento' });
  }
});

// ============================================
// ENDPOINT 5: Elimina prodotto
// ============================================
app.delete('/api/inventory/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const product = await Product.findByIdAndDelete(id);

    if (!product) {
      return res.status(404).json({ error: 'Prodotto non trovato' });
    }

    res.json({ success: true, message: 'Prodotto eliminato', product });
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ error: 'Errore nell\'eliminazione' });
  }
});

// ============================================
// FUNZIONE: Ottieni suggerimenti per categoria
// ============================================
async function getSuggestions(category) {
  const suggestions = {
    Dairy: [
      'Usalo nei dolci o caffè',
      'Prepara una salsa cremosa',
      'Congela per gelato fatto in casa',
    ],
    Bakery: [
      'Fai pangrattato tostato',
      'Usa come miglierina per budini',
      'Prepara pani di pane',
    ],
    Fruits: [
      'Prepara una marmellata',
      'Fai un succo o frullato',
      'Congela per sorbetto',
    ],
    Vegetables: [
      'Fai un minestrone congelato',
      'Prepara una salsa',
      'Metti sott\'olio o sottaceto',
    ],
    default: ['Controlla ricette online', 'Dona a qualcuno', 'Compostaggio sostenibile'],
  };

  return suggestions[category] || suggestions.default;
}

// ============================================
// SERVER START
// ============================================
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server avviato su http://localhost:${PORT}`);
});
