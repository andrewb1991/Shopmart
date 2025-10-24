// server.js - patched version created for deploy
// This file contains the improved CORS handling, request logging, PATCH handler and POST fallback
// Replace the backend's server.js with this file (or merge the changes) and deploy to Railway.

const express = require('express');
const axios = require('axios');
const mongoose = require('mongoose');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { translate } = require('@vitalets/google-translate-api');
const cors = require('cors');
require('dotenv').config();

const uuidv4 = () => crypto.randomUUID();
const JWT_SECRET = process.env.JWT_SECRET || 'shopmart_secret_key_change_in_production';

// Minimal translation dictionary (same as original, truncated here for brevity)
const translationDictionary = {
  'prosciutto': 'prosciutto',
  'ham': 'prosciutto',
  'basil': 'basilico',
  'egg': 'uovo',
  'butter': 'burro',
};
const translationCache = new Map();
async function translateToItalian(text) {
  if (!text) return text;
  const lowerText = text.toLowerCase().trim();
  if (translationDictionary[lowerText]) return translationDictionary[lowerText];
  if (translationCache.has(lowerText)) return translationCache.get(lowerText);
  try {
    await new Promise(r => setTimeout(r, 100));
    const result = await translate(text, { to: 'it' });
    translationCache.set(lowerText, result.text);
    return result.text;
  } catch (err) {
    return text;
  }
}

const app = express();

const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);
if (allowedOrigins.length === 0) {
  // Default safe set useful for local testing; in production set ALLOWED_ORIGINS env
  allowedOrigins.push('http://localhost:3000', 'http://localhost:5001');
}

app.use(cors({
  origin: function(origin, callback) {
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) return callback(null, true);
    return callback(new Error('CORS policy: origin not allowed'), false);
  },
  methods: ['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
  credentials: true
}));

// Simple request logger to trace incoming requests and origin
app.use((req, res, next) => {
  console.log(new Date().toISOString(), req.method, req.path, 'Origin:', req.headers.origin || 'none');
  res.setHeader('Vary', 'Origin');
  next();
});

app.use(express.json());

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/warehouse';
mongoose.connect(MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('✓ MongoDB connesso'))
  .catch((err) => console.error('✗ Errore MongoDB:', err.message));

// Schemas
const productSchema = new mongoose.Schema({
  id: { type: String, default: () => uuidv4() },
  barcode: { type: String, required: true },
  productName: { type: String, required: true },
  brand: String,
  category: String,
  quantity: { type: Number, required: true },
  unit: { type: String, default: 'pz' },
  expiryDate: { type: Date, required: true },
  dateAdded: { type: Date, default: Date.now },
  ingredients: String,
  nutritionInfo: Object,
  imageUrl: String,
  suggestions: [String],
  userId: String,
}, { timestamps: true });
const Product = mongoose.model('Product', productSchema);

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String },
  firstName: String,
  lastName: String,
  displayName: String,
  photoUrl: String,
  googleId: { type: String, unique: true, sparse: true },
  notificationSettings: { enabled: { type: Boolean, default: true }, urgentDays: { type: Number, default: 3 }, warningDays: { type: Number, default: 7 } },
}, { timestamps: true });

userSchema.pre('save', async function(next) {
  if (!this.isModified('password') || !this.password) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  try { return await bcrypt.compare(candidatePassword, this.password); } catch (e) { return false; }
};

const User = mongoose.model('User', userSchema);

// Auth middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token mancante' });
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      console.error('Token verification error:', err);
      return res.status(403).json({ error: 'Token non valido' });
    }
    req.user = user;
    next();
  });
};

// ------------------ AUTH ROUTES ------------------
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email e password sono obbligatori' });
    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email già registrata' });
    const user = new User({ email, password, firstName, lastName, displayName: `${firstName} ${lastName}` });
    await user.save();
    const token = jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    res.status(201).json({ success: true, user: { id: user._id.toString(), email: user.email, firstName: user.firstName, lastName: user.lastName, displayName: user.displayName, photoUrl: user.photoUrl }, token });
  } catch (err) { console.error('Errore registrazione:', err); res.status(500).json({ error: 'Errore durante la registrazione' }); }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email e password sono obbligatori' });
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ error: 'Credenziali non valide' });
    const ok = await user.comparePassword(password);
    if (!ok) return res.status(401).json({ error: 'Credenziali non valide' });
    const token = jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ success: true, user: { id: user._id.toString(), email: user.email, firstName: user.firstName, lastName: user.lastName, displayName: user.displayName }, token });
  } catch (err) { console.error('Errore login:', err); res.status(500).json({ error: 'Errore durante il login' }); }
});

// Google sign-in (minimal)
app.post('/api/auth/google', async (req, res) => {
  try {
    const { googleId, email, displayName, photoUrl, firstName, lastName } = req.body;
    if (!googleId || !email) return res.status(400).json({ error: 'Google ID ed email sono obbligatori' });
    let user = await User.findOne({ $or: [{ googleId }, { email }] });
    if (user) {
      if (!user.googleId) { user.googleId = googleId; await user.save(); }
    } else {
      user = new User({ googleId, email, displayName: displayName || `${firstName} ${lastName}`, photoUrl, firstName, lastName });
      await user.save();
    }
    const token = jwt.sign({ id: user._id.toString(), email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ success: true, user: { id: user._id.toString(), email: user.email, firstName: user.firstName, lastName: user.lastName, displayName: user.displayName }, token });
  } catch (err) { console.error('Errore Google Sign-In:', err); res.status(500).json({ error: 'Errore durante l\'autenticazione con Google' }); }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) return res.status(404).json({ error: 'Utente non trovato' });
    res.json({ success: true, user: { id: user._id.toString(), email: user.email, firstName: user.firstName, lastName: user.lastName, displayName: user.displayName, photoUrl: user.photoUrl } });
  } catch (err) { console.error('Errore recupero utente:', err); res.status(500).json({ error: 'Errore nel recupero dei dati utente' }); }
});

// ------------------ INVENTORY ------------------
app.post('/api/inventory/add', authenticateToken, async (req, res) => {
  try {
    const { barcode, productName, brand, category, quantity, unit, expiryDate, ingredients, nutritionInfo, imageUrl, suggestions } = req.body;
    if (!barcode || !productName || !expiryDate) return res.status(400).json({ error: 'Campi obbligatori mancanti' });
    const newProduct = new Product({ barcode, productName, brand, category, quantity, unit: unit || 'pz', expiryDate: new Date(expiryDate), ingredients, nutritionInfo, imageUrl, suggestions: suggestions || [], userId: req.user.id });
    await newProduct.save();
    res.json({ success: true, product: newProduct, message: 'Prodotto aggiunto' });
  } catch (err) { console.error('Errore add inventory:', err); res.status(500).json({ error: 'Errore nell\'aggiunta del prodotto' }); }
});

app.get('/api/inventory', authenticateToken, async (req, res) => {
  try {
    const products = await Product.find({ userId: req.user.id });
    const inventoryWithStatus = products.map(product => {
      const expiryDate = new Date(product.expiryDate);
      const today = new Date();
      const daysLeft = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));
      let status = 'OK'; if (daysLeft <= 0) status = 'SCADUTO'; else if (daysLeft <= 3) status = 'URGENTE'; else if (daysLeft <= 7) status = 'ATTENZIONE';
      const productObj = product.toObject();
      return { ...productObj, id: productObj._id.toString(), daysLeft, status };
    });
    const sorted = inventoryWithStatus.sort((a, b) => a.daysLeft - b.daysLeft);
    res.json({ success: true, products: sorted });
  } catch (err) { console.error('Errore get inventory:', err); res.status(500).json({ error: 'Errore nel recupero inventario' }); }
});

// PATCH quantity (preferred)
app.patch('/api/inventory/:id/quantity', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params; const { quantity } = req.body;
    if (quantity === undefined || quantity < 0) return res.status(400).json({ error: 'Quantità non valida' });
    const product = await Product.findOneAndUpdate({ _id: id, userId: req.user.id }, { quantity }, { new: true });
    if (!product) return res.status(404).json({ error: 'Prodotto non trovato' });
    res.json({ success: true, product, message: 'Quantità aggiornata' });
  } catch (err) { console.error('Errore patch quantity:', err); res.status(500).json({ error: 'Errore nell\'aggiornamento della quantità' }); }
});

// POST fallback for quantity updates
app.post('/api/inventory/:id/quantity', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params; const { quantity } = req.body;
    if (quantity === undefined || quantity < 0) return res.status(400).json({ error: 'Quantità non valida' });
    const product = await Product.findOneAndUpdate({ _id: id, userId: req.user.id }, { quantity }, { new: true });
    if (!product) return res.status(404).json({ error: 'Prodotto non trovato' });
    console.log(`✓ Quantity updated via POST for ${id} by user ${req.user.id}`);
    res.json({ success: true, product, message: 'Quantità aggiornata (POST fallback)' });
  } catch (err) { console.error('Errore fallback POST quantity:', err); res.status(500).json({ error: 'Errore interno' }); }
});

// PATCH full product
app.patch('/api/inventory/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params; const { productName, brand, quantity, unit, expiryDate } = req.body;
    if (!productName || quantity === undefined || !expiryDate) return res.status(400).json({ error: 'Campi obbligatori mancanti' });
    if (quantity < 0) return res.status(400).json({ error: 'Quantità non valida' });
    const product = await Product.findOneAndUpdate({ _id: id, userId: req.user.id }, { productName, brand, quantity, unit, expiryDate: new Date(expiryDate) }, { new: true });
    if (!product) return res.status(404).json({ error: 'Prodotto non trovato' });
    res.json({ success: true, product, message: 'Prodotto aggiornato' });
  } catch (err) { console.error('Errore patch product:', err); res.status(500).json({ error: 'Errore nell\'aggiornamento del prodotto' }); }
});

app.put('/api/inventory/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params; const { quantity } = req.body;
    const product = await Product.findOneAndUpdate({ _id: id, userId: req.user.id }, { quantity }, { new: true });
    if (!product) return res.status(404).json({ error: 'Prodotto non trovato' });
    res.json({ success: true, product, message: 'Quantità aggiornata' });
  } catch (err) { console.error('Errore put inventory:', err); res.status(500).json({ error: 'Errore nell\'aggiornamento' }); }
});

app.delete('/api/inventory/:id', authenticateToken, async (req, res) => {
  try { const { id } = req.params; const product = await Product.findOneAndDelete({ _id: id, userId: req.user.id }); if (!product) return res.status(404).json({ error: 'Prodotto non trovato' }); res.json({ success: true, message: 'Prodotto eliminato', product }); } catch (err) { console.error('Errore delete inventory:', err); res.status(500).json({ error: 'Errore nell\'eliminazione' }); }
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
// ENDPOINT: Lookup prodotto da OpenFoodFacts
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

// -- minimal recipes endpoints (keep as-is or extend)
app.post('/api/recipes/suggest', async (req, res) => {
  try {
    const { ingredients } = req.body; if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) return res.status(400).json({ error: 'Ingredienti richiesti' });
    const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY; if (!SPOONACULAR_API_KEY) return res.status(500).json({ error: 'API key non configurata' });
    const ingredientString = ingredients.join(',');
    const response = await axios.get('https://api.spoonacular.com/recipes/findByIngredients', { params: { apiKey: SPOONACULAR_API_KEY, ingredients: ingredientString, number: 10, ranking: 2, ignorePantry: true } });
    const recipes = response.data.map(recipe => ({ id: recipe.id, title: recipe.title, image: recipe.image, usedIngredientCount: recipe.usedIngredientCount, missedIngredientCount: recipe.missedIngredientCount, usedIngredients: recipe.usedIngredients.map(i => i.name), missedIngredients: recipe.missedIngredients.map(i => i.name) }));
    res.json({ success: true, recipes });
  } catch (err) { console.error('Errore suggest recipes:', err); if (err.response) return res.status(err.response.status).json({ error: 'Errore API ricette', details: err.response.data }); res.status(500).json({ error: 'Errore nella ricerca delle ricette' }); }
});

// Start server
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server avviato su port ${PORT}`));

// Helpful note: set ALLOWED_ORIGINS in Railway to include your Firebase hosting origin(s),
// for example: ALLOWED_ORIGINS=https://shopmart-app-ceb98.web.app,https://shopmart-app-ceb98.firebaseapp.com
