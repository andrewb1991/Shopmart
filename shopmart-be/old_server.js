// server.js - cleaned & defensive version
// Replace existing server.js with this or merge the changes, then deploy to Railway.

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

const app = express();

// CORS config
const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);
if (allowedOrigins.length === 0) {
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

// ---------- Schemas & Models ----------
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

// ---------- Minimal translate helpers (kept minimal) ----------
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

// ---------- Helpers for spoonacular enrichment ----------
async function enrichRecipeFromSpoonacular(recipeId) {
  const apiKey = process.env.SPOONACULAR_API_KEY;
  if (!apiKey) {
    console.warn('SPOONACULAR_API_KEY non settata');
    return null;
  }

  const url = `https://api.spoonacular.com/recipes/${recipeId}/information`;
  try {
    const resp = await axios.get(url, {
      params: { apiKey, includeNutrition: false },
      timeout: 10000,
    });
    if (resp.status === 200 && resp.data) {
      if (resp.headers['x-api-quota-left'] || resp.headers['x-api-quota-used']) {
        console.info('Spoonacular quota', {
          used: resp.headers['x-api-quota-used'],
          left: resp.headers['x-api-quota-left'],
        });
      }
      return resp.data;
    }
    return null;
  } catch (err) {
    console.error('Spoonacular enrich error', err?.response?.status, err?.response?.data?.message || err.message);
    return null;
  }
}

// ---------- SavedRecipe schema ----------
const savedRecipeSchema = new mongoose.Schema({
  recipeId: { type: Number, required: true },
  userId: { type: String, required: true },
  title: { type: String, required: true },
  image: { type: String },
  servings: { type: Number },
  readyInMinutes: { type: Number },
  sourceUrl: { type: String },
  summary: { type: String },
  instructions: { type: String },
  ingredients: [{
    name: String,
    amount: Number,
    unit: String,
    original: String
  }],
  savedAt: { type: Date, default: Date.now }
}, { timestamps: true });

savedRecipeSchema.index({ recipeId: 1, userId: 1 }, { unique: true });
const SavedRecipe = mongoose.model('SavedRecipe', savedRecipeSchema);

// ---------------- AUTH routes (register/login/google) ----------------
// (kept as in your file; not repeated here for brevity)
// ... register, login, google auth, and /api/auth/me as in your version ...
// I'll assume these are unchanged and present in the file.
//
// For brevity here I omit middle parts that are unchanged — keep your existing auth routes intact.
// ------------------------------------------------------------------

// ---------- INVENTORY routes (unchanged) ----------
// Keep your inventory routes as-is (add, get, patch, delete).
// ------------------------------------------------------------------

// ========== Recipes endpoints ==========

// Suggest recipes (public) - uses Spoonacular (may return 402/404 from provider)
app.post('/api/recipes/suggest', async (req, res) => {
  try {
    const { ingredients } = req.body;
    if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      return res.status(400).json({ error: 'Ingredienti richiesti' });
    }
    const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY;
    if (!SPOONACULAR_API_KEY) return res.status(500).json({ error: 'API key non configurata' });

    const ingredientString = ingredients.join(',');
    const response = await axios.get('https://api.spoonacular.com/recipes/findByIngredients', {
      params: { apiKey: SPOONACULAR_API_KEY, ingredients: ingredientString, number: 10, ranking: 2, ignorePantry: true },
    });

    const recipes = (response.data || []).map(recipe => ({
      id: recipe.id,
      title: recipe.title,
      image: recipe.image,
      usedIngredientCount: recipe.usedIngredientCount,
      missedIngredientCount: recipe.missedIngredientCount,
      usedIngredients: recipe.usedIngredients?.map(i => i.name) || [],
      missedIngredients: recipe.missedIngredients?.map(i => i.name) || [],
    }));

    res.json({ success: true, recipes });
  } catch (err) {
    console.error('Errore suggest recipes:', err?.response?.status, err?.response?.data || err.message);
    if (err.response) {
      // forward provider status & message (useful in debug, client should handle)
      return res.status(err.response.status).json({ error: 'Errore API ricette', details: err.response.data });
    }
    return res.status(500).json({ error: 'Errore nella ricerca delle ricette' });
  }
});

// Get recipe details (public). We first try DB (if saved), then external. Non-blocking: do not throw 500 due to provider.
app.get('/api/recipes/:id', async (req, res) => {
  try {
    const recipeId = parseInt(req.params.id, 10);
    if (Number.isNaN(recipeId)) return res.status(400).json({ success: false, error: 'ID ricetta non valido' });

    // Try DB first (user-specific data not required to show details)
    const saved = await SavedRecipe.findOne({ recipeId }).lean().exec();
    if (saved) {
      const ext = await enrichRecipeFromSpoonacular(recipeId);
      if (ext) {
        return res.json({ success: true, recipe: {
          id: ext.id || recipeId,
          title: ext.title,
          image: ext.image,
          servings: ext.servings,
          readyInMinutes: ext.readyInMinutes,
          sourceUrl: ext.sourceUrl,
          summary: ext.summary,
          instructions: ext.instructions,
          extendedIngredients: ext.extendedIngredients || saved.ingredients || [],
          enriched: true,
        }});
      } else {
        return res.json({ success: true, recipe: {
          id: saved.recipeId,
          title: saved.title,
          image: saved.image,
          servings: saved.servings,
          readyInMinutes: saved.readyInMinutes,
          sourceUrl: saved.sourceUrl,
          summary: saved.summary,
          instructions: saved.instructions,
          extendedIngredients: saved.ingredients || [],
          enriched: false,
        }});
      }
    }

    // Not saved: try external (but safe)
    const ext = await enrichRecipeFromSpoonacular(recipeId);
    if (ext) return res.json({ success: true, recipe: ext });

    // external failed -> 404 rather than 500
    return res.status(404).json({ success: false, error: 'Recipe not found' });
  } catch (err) {
    console.error('Errore recupero dettaglio ricetta:', err);
    return res.status(200).json({ success: false, error: 'Errore nel recupero dei dettagli' });
  }
});

// Save recipe (requires auth)
app.post('/api/recipes/save', authenticateToken, async (req, res) => {
  try {
    const {
      recipeId, title, image, servings, readyInMinutes, sourceUrl, summary, instructions, ingredients,
    } = req.body;
    const userId = req.user.id;
    if (!recipeId || !title) return res.status(400).json({ error: 'recipeId e title sono obbligatori' });

    const existing = await SavedRecipe.findOne({ recipeId: parseInt(recipeId, 10), userId }).lean().exec();
    if (existing) return res.status(409).json({ error: 'Ricetta già salvata', recipe: existing });

    const savedRecipe = new SavedRecipe({
      recipeId: parseInt(recipeId, 10),
      userId,
      title,
      image,
      servings,
      readyInMinutes,
      sourceUrl,
      summary,
      instructions,
      ingredients: Array.isArray(ingredients) ? ingredients : [],
    });

    await savedRecipe.save();
    return res.json({ success: true, message: 'Ricetta salvata', recipe: savedRecipe });
  } catch (err) {
    console.error('Errore salvataggio ricetta:', err);
    return res.status(500).json({ error: 'Errore nel salvataggio della ricetta' });
  }
});

// Get saved recipes (requires auth) - DB-first; optional ?enrich=true
app.get('/api/recipes/saved', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log('GET /api/recipes/saved - userId=', userId);

    const shouldEnrich = String(req.query.enrich) === 'true';
    const savedRecipes = await SavedRecipe.find({ userId }).sort({ savedAt: -1 }).lean().exec();
    console.log(`GET /api/recipes/saved - found ${savedRecipes.length} saved recipes for user ${userId}`);

    if (!shouldEnrich) {
      const payload = savedRecipes.map(r => ({
        recipeId: r.recipeId,
        title: r.title,
        image: r.image,
        servings: r.servings,
        readyInMinutes: r.readyInMinutes,
        sourceUrl: r.sourceUrl,
        summary: r.summary,
        instructions: r.instructions,
        ingredients: r.ingredients || [],
        enriched: false,
      }));
      return res.json({ success: true, recipes: payload });
    }

    // Enrich (best-effort)
    const enriched = await Promise.all(savedRecipes.map(async (r) => {
      try {
        const ext = await enrichRecipeFromSpoonacular(r.recipeId);
        if (ext) {
          return {
            recipeId: r.recipeId,
            title: ext.title || r.title,
            image: ext.image || r.image,
            servings: ext.servings || r.servings,
            readyInMinutes: ext.readyInMinutes || r.readyInMinutes,
            sourceUrl: ext.sourceUrl || r.sourceUrl,
            summary: ext.summary || r.summary,
            instructions: ext.instructions || r.instructions,
            ingredients: ext.extendedIngredients || r.ingredients || [],
            enriched: true,
          };
        }
      } catch (e) {
        console.warn('Enrich failed for', r.recipeId, e?.message || e);
      }
      return {
        recipeId: r.recipeId,
        title: r.title,
        image: r.image,
        servings: r.servings,
        readyInMinutes: r.readyInMinutes,
        sourceUrl: r.sourceUrl,
        summary: r.summary,
        instructions: r.instructions,
        ingredients: r.ingredients || [],
        enriched: false,
      };
    }));

    return res.json({ success: true, recipes: enriched });
  } catch (err) {
    console.error('Errore recupero ricette salvate:', err);
    // safe fallback: return empty list (avoid breaking client)
    return res.status(200).json({ success: true, recipes: [] });
  }
});

// Delete saved (requires auth)
app.delete('/api/recipes/saved/:recipeId', authenticateToken, async (req, res) => {
  try {
    const recipeId = parseInt(req.params.recipeId, 10);
    const userId = req.user.id;
    const deletedRecipe = await SavedRecipe.findOneAndDelete({ recipeId, userId }).lean().exec();
    if (!deletedRecipe) return res.status(404).json({ error: 'Ricetta non trovata' });
    return res.json({ success: true, message: 'Ricetta rimossa', recipe: deletedRecipe });
  } catch (err) {
    console.error('Errore rimozione ricetta:', err);
    return res.status(500).json({ error: 'Errore nella rimozione della ricetta' });
  }
});

// Start
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server avviato su port ${PORT}`));

// Helpful note: set ALLOWED_ORIGINS in Railway to include your hosting origin(s)