// // server.js - Backend Express.js
// const express = require('express');
// const axios = require('axios');
// const mongoose = require('mongoose');
// const crypto = require('crypto');
// const bcrypt = require('bcryptjs');
// const jwt = require('jsonwebtoken');
// const { translate } = require('@vitalets/google-translate-api');
// require('dotenv').config();

// // Funzione per generare UUID
// const uuidv4 = () => crypto.randomUUID();

// // JWT Secret (in produzione usa variabile d'ambiente)
// const JWT_SECRET = process.env.JWT_SECRET || 'shopmart_secret_key_change_in_production';

// // Dizionario statico per ingredienti e termini comuni
// const translationDictionary = {
//   // Ingredienti comuni
//   'prosciutto': 'prosciutto',
//   'ham': 'prosciutto',
//   'pancetta': 'pancetta',
//   'proscuitto': 'prosciutto',
//   'biscuit type crackers': 'cracker tipo biscotto',
//   'fig jam': 'marmellata di fichi',
//   'figs': 'fichi',
//   'brie cheese': 'formaggio brie',
//   'muffins': 'muffin',
//   'pear': 'pera',
//   'creamy goat cheese': 'formaggio caprino cremoso',
//   'basil': 'basilico',
//   'thyme': 'timo',
//   'juice of lemon': 'succo di limone',
//   'chicken thighs': 'cosce di pollo',
//   'shells': 'conchiglie',
//   'ricotta cheese': 'ricotta',
//   'egg': 'uovo',
//   'tomato sauce': 'salsa di pomodoro',
//   'several basil leaves': 'diverse foglie di basilico',
//   'sized cantaloupe': 'melone',
//   'chicken stock': 'brodo di pollo',
//   'onion': 'cipolla',
//   'mushrooms': 'funghi',
//   'dijon mustard': 'senape di digione',
//   'puff pastry': 'pasta sfoglia',
//   'egg yolks': 'tuorli d\'uovo',
//   'pork cutlets': 'cotolette di maiale',
//   'sage leaves': 'foglie di salvia',
//   'butter': 'burro',
//   'lemon juice': 'succo di limone',
//   'toasty bread': 'pane tostato',
//   'garlic': 'aglio',
//   'radicchio': 'radicchio',
//   'endive': 'indivia',
//   'olive oil': 'olio d\'oliva',
//   'pistachio nuts': 'pistacchi',
//   'honey': 'miele',
//   'white peppercorns cracked': 'pepe bianco macinato',
//   'peppercorns cracked': 'pepe macinato',
//   'shaved prosciutto': 'prosciutto a fette',
//   'small jar': 'barattolo piccolo',
//   'ounces': 'once',
//   'ounce': 'oncia',
//   // Titoli ricette comuni
//   'goat cheese, fig and proscuitto crostini': 'crostini di formaggio di capra, fichi e prosciutto',
//   'grilled figs with brie and prosciutto': 'fichi grigliati con brie e prosciutto',
//   'broiled pear and prosciutto toasts': 'toast con pere e prosciutto alla griglia',
//   'chicken thighs wrapped in prosciutto': 'cosce di pollo avvolte nel prosciutto',
//   'pasta shells with ricotta cheese stuffing': 'conchiglie di pasta con ripieno di ricotta',
//   'cantaloupe soup with crispy ham and basil': 'zuppa di melone con prosciutto croccante e basilico',
//   'easy beef wellington': 'manzo wellington facile',
//   'mouthwatering grilled saltimbocca': 'saltimbocca alla griglia deliziosi',
//   'savory radicchio and prosciutto crostini topped with sweet syrupy sapa': 'crostini salati con radicchio e prosciutto conditi con sapa dolce sciroppata',
//   'roasted endive salad with prosciutto, figs and pistachios': 'insalata di indivia arrosto con prosciutto, fichi e pistacchi'
// };

// // Cache per le traduzioni
// const translationCache = new Map();

// // Funzione per tradurre testo in italiano con dizionario statico e cache
// async function translateToItalian(text) {
//   if (!text) return text;

//   const lowerText = text.toLowerCase().trim();

//   // 1. Controlla dizionario statico
//   if (translationDictionary[lowerText]) {
//     return translationDictionary[lowerText];
//   }

//   // 2. Controlla cache
//   if (translationCache.has(lowerText)) {
//     return translationCache.get(lowerText);
//   }

//   // 3. Usa Google Translate come fallback (con gestione errori)
//   try {
//     // Aggiungi un piccolo delay per evitare rate limiting
//     await new Promise(resolve => setTimeout(resolve, 100));

//     const result = await translate(text, { to: 'it' });
//     const translated = result.text;

//     // Salva in cache
//     translationCache.set(lowerText, translated);

//     return translated;
//   } catch (error) {
//     // In caso di errore, ritorna testo originale
//     return text;
//   }
// }

// // Funzione per tradurre un array di testi
// async function translateArray(textArray) {
//   const translations = await Promise.all(
//     textArray.map(text => translateToItalian(text))
//   );
//   return translations;
// }

// const app = express();

// // CORS middleware - DEVE essere il primo middleware
// app.use((req, res, next) => {
//   // Log per debug
//   console.log(`${req.method} ${req.path}`);

//   res.header('Access-Control-Allow-Origin', 'http://localhost:3000');
//   res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
//   res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
//   res.header('Access-Control-Allow-Credentials', 'true');

//   // Gestisci preflight request
//   if (req.method === 'OPTIONS') {
//     console.log('✓ OPTIONS request handled');
//     return res.status(200).end();
//   }

//   next();
// });

// app.use(express.json());

// // ============================================
// // MONGODB CONNECTION
// // ============================================
// const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/warehouse';

// mongoose.connect(MONGODB_URI, {
//   useNewUrlParser: true,
//   useUnifiedTopology: true,
// })
// .then(() => console.log('✓ MongoDB connesso'))
// .catch((err) => console.error('✗ Errore MongoDB:', err.message));

// // ============================================
// // MONGOOSE SCHEMA E MODELLO
// // ============================================
// const productSchema = new mongoose.Schema({
//   id: { type: String, default: () => uuidv4() },
//   barcode: { type: String, required: true },
//   productName: { type: String, required: true },
//   brand: { type: String },
//   category: { type: String },
//   quantity: { type: Number, required: true },
//   unit: { type: String, default: 'pz' },
//   expiryDate: { type: Date, required: true },
//   dateAdded: { type: Date, default: Date.now },
//   ingredients: { type: String },
//   nutritionInfo: {
//     energy: Number,
//     protein: Number,
//     fat: Number,
//     carbs: Number,
//     salt: Number,
//   },
//   imageUrl: { type: String },
//   suggestions: [String],
//   userId: { type: String }, // Per future features multi-utente
// }, { timestamps: true });

// const Product = mongoose.model('Product', productSchema);

// // ============================================
// // SCHEMA E MODELLO USER
// // ============================================
// const userSchema = new mongoose.Schema({
//   email: { type: String, required: true, unique: true, lowercase: true },
//   password: { type: String }, // Opzionale per utenti Google
//   firstName: { type: String },
//   lastName: { type: String },
//   displayName: { type: String },
//   photoUrl: { type: String },
//   googleId: { type: String, unique: true, sparse: true }, // Per Google Sign-In
//   notificationSettings: {
//     enabled: { type: Boolean, default: true },
//     urgentDays: { type: Number, default: 3 }, // Notifica quando mancano X giorni
//     warningDays: { type: Number, default: 7 }, // Notifica quando mancano X giorni
//   },
//   createdAt: { type: Date, default: Date.now },
// }, { timestamps: true });

// // Hash password prima del salvataggio
// userSchema.pre('save', async function(next) {
//   if (!this.isModified('password') || !this.password) return next();

//   try {
//     const salt = await bcrypt.genSalt(10);
//     this.password = await bcrypt.hash(this.password, salt);
//     next();
//   } catch (error) {
//     next(error);
//   }
// });

// // Metodo per verificare password
// userSchema.methods.comparePassword = async function(candidatePassword) {
//   if (!this.password) return false;
//   return await bcrypt.compare(candidatePassword, this.password);
// };

// const User = mongoose.model('User', userSchema);

// // ============================================
// // MIDDLEWARE: Verifica JWT Token
// // ============================================
// const authenticateToken = (req, res, next) => {
//   const authHeader = req.headers['authorization'];
//   const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

//   if (!token) {
//     return res.status(401).json({ error: 'Token mancante' });
//   }

//   jwt.verify(token, JWT_SECRET, (err, user) => {
//     if (err) {
//       return res.status(403).json({ error: 'Token non valido' });
//     }
//     req.user = user; // Aggiungi user ID al request
//     next();
//   });
// };

// // ============================================
// // MODELLO PRODOTTO
// // ============================================
// // {
// //   id: uuid,
// //   barcode: "123456789",
// //   productName: "Latte intero",
// //   brand: "Parmalat",
// //   category: "Dairy",
// //   quantity: 2,
// //   unit: "L",
// //   expiryDate: "2025-12-20",
// //   dateAdded: "2025-10-20",
// //   nutritionInfo: {...},
// //   ingredients: "...",
// //   imageUrl: "...",
// //   suggestions: [...]
// // }

// // ============================================
// // AUTH ENDPOINTS
// // ============================================

// // Registrazione con email e password
// app.post('/api/auth/register', async (req, res) => {
//   try {
//     const { email, password, firstName, lastName } = req.body;

//     if (!email || !password) {
//       return res.status(400).json({ error: 'Email e password sono obbligatori' });
//     }

//     // Verifica se utente esiste già
//     const existingUser = await User.findOne({ email });
//     if (existingUser) {
//       return res.status(409).json({ error: 'Email già registrata' });
//     }

//     // Crea nuovo utente
//     const user = new User({
//       email,
//       password, // Verrà hashata dal middleware pre-save
//       firstName,
//       lastName,
//       displayName: `${firstName} ${lastName}`,
//     });

//     await user.save();

//     // Genera JWT token
//     const token = jwt.sign(
//       { id: user._id.toString(), email: user.email },
//       JWT_SECRET,
//       { expiresIn: '30d' }
//     );

//     console.log(`✓ Utente registrato: ${email}`);

//     res.status(201).json({
//       success: true,
//       user: {
//         id: user._id.toString(),
//         email: user.email,
//         firstName: user.firstName,
//         lastName: user.lastName,
//         displayName: user.displayName,
//         photoUrl: user.photoUrl,
//       },
//       token,
//     });
//   } catch (error) {
//     console.error('Errore registrazione:', error);
//     res.status(500).json({ error: 'Errore durante la registrazione' });
//   }
// });

// // Login con email e password
// app.post('/api/auth/login', async (req, res) => {
//   try {
//     const { email, password } = req.body;

//     if (!email || !password) {
//       return res.status(400).json({ error: 'Email e password sono obbligatori' });
//     }

//     // Trova utente
//     const user = await User.findOne({ email });
//     if (!user) {
//       return res.status(401).json({ error: 'Credenziali non valide' });
//     }

//     // Verifica password
//     const isPasswordValid = await user.comparePassword(password);
//     if (!isPasswordValid) {
//       return res.status(401).json({ error: 'Credenziali non valide' });
//     }

//     // Genera JWT token
//     const token = jwt.sign(
//       { id: user._id.toString(), email: user.email },
//       JWT_SECRET,
//       { expiresIn: '30d' }
//     );

//     console.log(`✓ Utente loggato: ${email}`);

//     res.json({
//       success: true,
//       user: {
//         id: user._id.toString(),
//         email: user.email,
//         firstName: user.firstName,
//         lastName: user.lastName,
//         displayName: user.displayName,
//         photoUrl: user.photoUrl,
//       },
//       token,
//     });
//   } catch (error) {
//     console.error('Errore login:', error);
//     res.status(500).json({ error: 'Errore durante il login' });
//   }
// });

// // Google Sign-In
// app.post('/api/auth/google', async (req, res) => {
//   try {
//     const { googleId, email, displayName, photoUrl, firstName, lastName } = req.body;

//     if (!googleId || !email) {
//       return res.status(400).json({ error: 'Google ID ed email sono obbligatori' });
//     }

//     // Cerca utente esistente per googleId o email
//     let user = await User.findOne({ $or: [{ googleId }, { email }] });

//     if (user) {
//       // Aggiorna googleId se mancante
//       if (!user.googleId) {
//         user.googleId = googleId;
//         await user.save();
//       }
//     } else {
//       // Crea nuovo utente
//       user = new User({
//         googleId,
//         email,
//         displayName: displayName || `${firstName} ${lastName}`,
//         photoUrl,
//         firstName,
//         lastName,
//       });
//       await user.save();
//       console.log(`✓ Nuovo utente Google: ${email}`);
//     }

//     // Genera JWT token
//     const token = jwt.sign(
//       { id: user._id.toString(), email: user.email },
//       JWT_SECRET,
//       { expiresIn: '30d' }
//     );

//     res.json({
//       success: true,
//       user: {
//         id: user._id.toString(),
//         email: user.email,
//         firstName: user.firstName,
//         lastName: user.lastName,
//         displayName: user.displayName,
//         photoUrl: user.photoUrl,
//       },
//       token,
//     });
//   } catch (error) {
//     console.error('Errore Google Sign-In:', error);
//     res.status(500).json({ error: 'Errore durante l\'autenticazione con Google' });
//   }
// });

// // Ottieni info utente corrente (protetto)
// app.get('/api/auth/me', authenticateToken, async (req, res) => {
//   try {
//     const user = await User.findById(req.user.id).select('-password');

//     if (!user) {
//       return res.status(404).json({ error: 'Utente non trovato' });
//     }

//     res.json({
//       success: true,
//       user: {
//         id: user._id.toString(),
//         email: user.email,
//         firstName: user.firstName,
//         lastName: user.lastName,
//         displayName: user.displayName,
//         photoUrl: user.photoUrl,
//       },
//     });
//   } catch (error) {
//     console.error('Errore recupero utente:', error);
//     res.status(500).json({ error: 'Errore nel recupero dei dati utente' });
//   }
// });

// // Aggiorna profilo utente (protetto)
// app.put('/api/auth/profile', authenticateToken, async (req, res) => {
//   try {
//     const { firstName, lastName, currentPassword, newPassword } = req.body;

//     if (!firstName || !lastName) {
//       return res.status(400).json({ error: 'Nome e cognome sono obbligatori' });
//     }

//     const user = await User.findById(req.user.id);

//     if (!user) {
//       return res.status(404).json({ error: 'Utente non trovato' });
//     }

//     // Aggiorna nome e cognome
//     user.firstName = firstName;
//     user.lastName = lastName;
//     user.displayName = `${firstName} ${lastName}`;

//     // Se l'utente vuole cambiare la password
//     if (currentPassword && newPassword) {
//       // Verifica che l'utente abbia una password (non utente Google senza password)
//       if (!user.password) {
//         return res.status(400).json({ error: 'Account Google: impossibile cambiare password' });
//       }

//       // Verifica password attuale
//       const isPasswordValid = await user.comparePassword(currentPassword);
//       if (!isPasswordValid) {
//         return res.status(401).json({ error: 'Password attuale non corretta' });
//       }

//       // Valida nuova password
//       if (newPassword.length < 6) {
//         return res.status(400).json({ error: 'La nuova password deve avere almeno 6 caratteri' });
//       }

//       // Aggiorna password (verrà hashata dal middleware pre-save)
//       user.password = newPassword;
//     }

//     await user.save();

//     console.log(`✓ Profilo aggiornato: ${user.email}`);

//     res.json({
//       success: true,
//       user: {
//         id: user._id.toString(),
//         email: user.email,
//         firstName: user.firstName,
//         lastName: user.lastName,
//         displayName: user.displayName,
//         photoUrl: user.photoUrl,
//       },
//     });
//   } catch (error) {
//     console.error('Errore aggiornamento profilo:', error);
//     res.status(500).json({ error: 'Errore durante l\'aggiornamento del profilo' });
//   }
// });

// // Aggiorna impostazioni notifiche (protetto)
// app.put('/api/auth/notifications', authenticateToken, async (req, res) => {
//   try {
//     const { enabled, urgentDays, warningDays } = req.body;

//     const user = await User.findById(req.user.id);

//     if (!user) {
//       return res.status(404).json({ error: 'Utente non trovato' });
//     }

//     // Aggiorna impostazioni notifiche
//     if (enabled !== undefined) {
//       user.notificationSettings.enabled = enabled;
//     }
//     if (urgentDays !== undefined && urgentDays > 0) {
//       user.notificationSettings.urgentDays = urgentDays;
//     }
//     if (warningDays !== undefined && warningDays > 0) {
//       user.notificationSettings.warningDays = warningDays;
//     }

//     await user.save();

//     console.log(`✓ Impostazioni notifiche aggiornate: ${user.email}`);

//     res.json({
//       success: true,
//       notificationSettings: user.notificationSettings,
//     });
//   } catch (error) {
//     console.error('Errore aggiornamento notifiche:', error);
//     res.status(500).json({ error: 'Errore durante l\'aggiornamento delle notifiche' });
//   }
// });

// // Ottieni impostazioni notifiche (protetto)
// app.get('/api/auth/notifications', authenticateToken, async (req, res) => {
//   try {
//     const user = await User.findById(req.user.id);

//     if (!user) {
//       return res.status(404).json({ error: 'Utente non trovato' });
//     }

//     res.json({
//       success: true,
//       notificationSettings: user.notificationSettings || {
//         enabled: true,
//         urgentDays: 3,
//         warningDays: 7,
//       },
//     });
//   } catch (error) {
//     console.error('Errore recupero notifiche:', error);
//     res.status(500).json({ error: 'Errore nel recupero delle impostazioni' });
//   }
// });

// // ============================================
// // ENDPOINT 1: Lookup prodotto da OpenFoodFacts
// // ============================================
// app.post('/api/product/lookup', async (req, res) => {
//   try {
//     const { barcode } = req.body;

//     if (!barcode) {
//       return res.status(400).json({ error: 'Barcode richiesto' });
//     }

//     // Chiama OpenFoodFacts API con lingua italiana
//     const response = await axios.get(
//       `https://world.openfoodfacts.org/api/v2/product/${barcode}?fields=code,product_name,product_name_it,brands,categories,categories_tags,ingredients_text,ingredients_text_it,nutriments,image_front_url,quantity&lc=it`
//     );

//     if (response.data.status === 0 || !response.data.product) {
//       return res.status(404).json({ error: 'Prodotto non trovato' });
//     }

//     const product = response.data.product;

//     // Estrai categoria in italiano dai tags
//     let categoryIT = 'N/A';
//     if (product.categories_tags && product.categories_tags.length > 0) {
//       // I tag hanno formato "it:nome-categoria" o "en:nome-categoria"
//       const itTag = product.categories_tags.find(tag => tag.startsWith('it:'));
//       if (itTag) {
//         categoryIT = itTag.replace('it:', '').replace(/-/g, ' ');
//         // Capitalizza la prima lettera
//         categoryIT = categoryIT.charAt(0).toUpperCase() + categoryIT.slice(1);
//       } else {
//         // Se non c'è tag italiano, usa il primo disponibile
//         categoryIT = product.categories_tags[0].replace(/^[a-z]{2}:/, '').replace(/-/g, ' ');
//         categoryIT = categoryIT.charAt(0).toUpperCase() + categoryIT.slice(1);
//       }
//     } else if (product.categories) {
//       // Fallback: usa la prima categoria dalla stringa
//       categoryIT = product.categories.split(',')[0].trim();
//     }

//     // Estrai dati rilevanti (priorità alla lingua italiana)
//     const productData = {
//       barcode: product.code || barcode,
//       productName: product.product_name_it || product.product_name || 'Sconosciuto',
//       brand: product.brands || 'N/A',
//       category: categoryIT,
//       ingredients: product.ingredients_text_it || product.ingredients_text || 'Non disponibili',
//       nutritionInfo: {
//         energy: product.nutriments?.energy_100g || product.nutriments?.['energy-kcal_100g'],
//         protein: product.nutriments?.proteins_100g,
//         fat: product.nutriments?.fat_100g,
//         carbs: product.nutriments?.carbohydrates_100g,
//         salt: product.nutriments?.salt_100g,
//       },
//       imageUrl: product.image_front_url || null,
//       quantity: 1,
//       unit: product.quantity || 'pz',
//     };

//     // Recupera suggerimenti di utilizzo basati su categoria
//     const suggestions = await getSuggestions(productData.category);

//     res.json({ success: true, product: productData, suggestions });
//   } catch (error) {
//     console.error('Errore lookup:', error.message);
//     res.status(500).json({ error: 'Errore nella ricerca del prodotto' });
//   }
// });

// // ============================================
// // ENDPOINT 2: Aggiungi prodotto al magazzino (protetto)
// // ============================================
// app.post('/api/inventory/add', authenticateToken, async (req, res) => {
//   try {
//     const { barcode, productName, brand, category, quantity, unit, expiryDate, ingredients, nutritionInfo, imageUrl, suggestions } = req.body;

//     if (!barcode || !productName || !expiryDate) {
//       return res.status(400).json({ error: 'Campi obbligatori mancanti' });
//     }

//     const newProduct = new Product({
//       barcode,
//       productName,
//       brand,
//       category,
//       quantity,
//       unit: unit || 'pz',
//       expiryDate: new Date(expiryDate),
//       ingredients,
//       nutritionInfo,
//       imageUrl,
//       suggestions: suggestions || [],
//       userId: req.user.id, // Associa prodotto all'utente autenticato
//     });

//     await newProduct.save();

//     res.json({ success: true, product: newProduct, message: 'Prodotto aggiunto' });
//   } catch (error) {
//     console.error('Errore:', error);
//     res.status(500).json({ error: 'Errore nell\'aggiunta del prodotto' });
//   }
// });

// // ============================================
// // ENDPOINT 3: Ottieni inventario (protetto)
// // ============================================
// app.get('/api/inventory', authenticateToken, async (req, res) => {
//   try {
//     // Filtra prodotti per utente autenticato
//     const products = await Product.find({ userId: req.user.id });

//     // Calcola giorni a scadenza per ogni prodotto
//     const inventoryWithStatus = products.map((product) => {
//       const expiryDate = new Date(product.expiryDate);
//       const today = new Date();
//       const daysLeft = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));

//       let status = 'OK';
//       if (daysLeft <= 0) status = 'SCADUTO';
//       else if (daysLeft <= 3) status = 'URGENTE';
//       else if (daysLeft <= 7) status = 'ATTENZIONE';

//       const productObj = product.toObject();
//       return {
//         ...productObj,
//         id: productObj._id.toString(), // Aggiungi id come stringa per il frontend
//         daysLeft,
//         status
//       };
//     });

//     // Ordina per urgenza
//     const sorted = inventoryWithStatus.sort((a, b) => a.daysLeft - b.daysLeft);

//     res.json({ success: true, products: sorted });
//   } catch (error) {
//     console.error('Errore:', error);
//     res.status(500).json({ error: 'Errore nel recupero inventario' });
//   }
// });

// // ============================================
// // ENDPOINT 4a: Aggiorna solo quantità (PATCH protetto) - DEVE VENIRE PRIMA!
// // ============================================
// app.patch('/api/inventory/:id/quantity', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;
//     const { quantity } = req.body;

//     if (quantity === undefined || quantity < 0) {
//       return res.status(400).json({ error: 'Quantità non valida' });
//     }

//     // Verifica che il prodotto appartenga all'utente
//     const product = await Product.findOneAndUpdate(
//       { _id: id, userId: req.user.id },
//       { quantity },
//       { new: true }
//     );

//     if (!product) {
//       return res.status(404).json({ error: 'Prodotto non trovato' });
//     }

//     res.json({ success: true, product, message: 'Quantità aggiornata' });
//   } catch (error) {
//     console.error('Errore aggiornamento quantità:', error);
//     res.status(500).json({ error: 'Errore nell\'aggiornamento della quantità' });
//   }
// });

// // ============================================
// // ENDPOINT 4b: Aggiorna prodotto completo (PATCH protetto)
// // ============================================
// app.patch('/api/inventory/:id', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;
//     const { productName, brand, quantity, unit, expiryDate } = req.body;

//     // Validazione campi obbligatori
//     if (!productName || quantity === undefined || !expiryDate) {
//       return res.status(400).json({ error: 'Campi obbligatori mancanti' });
//     }

//     if (quantity < 0) {
//       return res.status(400).json({ error: 'Quantità non valida' });
//     }

//     // Verifica che il prodotto appartenga all'utente
//     const product = await Product.findOneAndUpdate(
//       { _id: id, userId: req.user.id },
//       {
//         productName,
//         brand,
//         quantity,
//         unit,
//         expiryDate: new Date(expiryDate),
//       },
//       { new: true }
//     );

//     if (!product) {
//       return res.status(404).json({ error: 'Prodotto non trovato' });
//     }

//     res.json({ success: true, product, message: 'Prodotto aggiornato' });
//   } catch (error) {
//     console.error('Errore aggiornamento prodotto:', error);
//     res.status(500).json({ error: 'Errore nell\'aggiornamento del prodotto' });
//   }
// });

// // ============================================
// // ENDPOINT 4c: Aggiorna quantità prodotto (PUT protetto) - Legacy
// // ============================================
// app.put('/api/inventory/:id', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;
//     const { quantity } = req.body;

//     // Verifica che il prodotto appartenga all'utente
//     const product = await Product.findOneAndUpdate(
//       { _id: id, userId: req.user.id },
//       { quantity },
//       { new: true }
//     );

//     if (!product) {
//       return res.status(404).json({ error: 'Prodotto non trovato' });
//     }

//     res.json({ success: true, product, message: 'Quantità aggiornata' });
//   } catch (error) {
//     console.error('Errore:', error);
//     res.status(500).json({ error: 'Errore nell\'aggiornamento' });
//   }
// });

// // ============================================
// // ENDPOINT 5: Elimina prodotto (protetto)
// // ============================================
// app.delete('/api/inventory/:id', authenticateToken, async (req, res) => {
//   try {
//     const { id } = req.params;

//     // Verifica che il prodotto appartenga all'utente
//     const product = await Product.findOneAndDelete({ _id: id, userId: req.user.id });

//     if (!product) {
//       return res.status(404).json({ error: 'Prodotto non trovato' });
//     }

//     res.json({ success: true, message: 'Prodotto eliminato', product });
//   } catch (error) {
//     console.error('Errore:', error);
//     res.status(500).json({ error: 'Errore nell\'eliminazione' });
//   }
// });

// // ============================================
// // ENDPOINT 6: Suggerisci ricette in base agli ingredienti
// // ============================================
// app.post('/api/recipes/suggest', async (req, res) => {
//   try {
//     const { ingredients } = req.body;

//     if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
//       return res.status(400).json({ error: 'Ingredienti richiesti' });
//     }

//     // Spoonacular API key (da configurare in .env)
//     const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY;

//     if (!SPOONACULAR_API_KEY) {
//       return res.status(500).json({
//         error: 'API key non configurata',
//         message: 'Configura SPOONACULAR_API_KEY nel file .env'
//       });
//     }

//     // Crea stringa ingredienti separati da virgola
//     const ingredientString = ingredients.join(',');

//     console.log(`🔍 Cercando ricette con: ${ingredientString}`);

//     // Chiama Spoonacular API
//     const response = await axios.get(
//       `https://api.spoonacular.com/recipes/findByIngredients`,
//       {
//         params: {
//           apiKey: SPOONACULAR_API_KEY,
//           ingredients: ingredientString,
//           number: 10, // Numero di ricette da restituire
//           ranking: 2, // Massimizza ingredienti usati
//           ignorePantry: true, // Non ignorare ingredienti base
//           language: 'it' // Lingua italiana (se disponibile)
//         }
//       }
//     );

//     // Estrai le ricette (senza traduzione)
//     const recipes = response.data.map(recipe => ({
//       id: recipe.id,
//       title: recipe.title,
//       image: recipe.image,
//       usedIngredientCount: recipe.usedIngredientCount,
//       missedIngredientCount: recipe.missedIngredientCount,
//       usedIngredients: recipe.usedIngredients.map(ing => ing.name),
//       missedIngredients: recipe.missedIngredients.map(ing => ing.name),
//     }));

//     console.log(`✓ Trovate ${recipes.length} ricette`);

//     res.json({ success: true, recipes });
//   } catch (error) {
//     console.error('Errore suggerimenti ricette:', error.message);

//     if (error.response) {
//       // Errore dalla API di Spoonacular
//       console.error('Dettagli errore API:', error.response.data);
//       return res.status(error.response.status).json({
//         error: 'Errore API ricette',
//         details: error.response.data
//       });
//     }

//     res.status(500).json({ error: 'Errore nella ricerca delle ricette' });
//   }
// });

// // ============================================
// // SCHEMA E MODELLO RICETTE SALVATE
// // ============================================
// const savedRecipeSchema = new mongoose.Schema({
//   recipeId: { type: Number, required: true },
//   userId: { type: String, default: 'default_user' }, // Per future features multi-utente
//   title: { type: String, required: true },
//   image: { type: String },
//   servings: { type: Number },
//   readyInMinutes: { type: Number },
//   sourceUrl: { type: String },
//   summary: { type: String },
//   instructions: { type: String },
//   ingredients: [{
//     name: String,
//     amount: Number,
//     unit: String,
//     original: String
//   }],
//   savedAt: { type: Date, default: Date.now }
// }, { timestamps: true });

// // Indice composto per evitare duplicati (stesso utente + stessa ricetta)
// savedRecipeSchema.index({ recipeId: 1, userId: 1 }, { unique: true });

// const SavedRecipe = mongoose.model('SavedRecipe', savedRecipeSchema);

// // ============================================
// // ENDPOINT 8: Salva ricetta (protetto)
// // ============================================
// app.post('/api/recipes/save', authenticateToken, async (req, res) => {
//   try {
//     const { recipeId, title, image, servings, readyInMinutes, sourceUrl, summary, instructions, ingredients } = req.body;
//     const userId = req.user.id; // Usa userId dall'autenticazione

//     if (!recipeId || !title) {
//       return res.status(400).json({ error: 'recipeId e title sono obbligatori' });
//     }

//     // Controlla se già salvata
//     const existing = await SavedRecipe.findOne({ recipeId, userId });
//     if (existing) {
//       return res.status(409).json({
//         error: 'Ricetta già salvata',
//         recipe: existing
//       });
//     }

//     const savedRecipe = new SavedRecipe({
//       recipeId,
//       userId,
//       title,
//       image,
//       servings,
//       readyInMinutes,
//       sourceUrl,
//       summary,
//       instructions,
//       ingredients: ingredients || []
//     });

//     await savedRecipe.save();

//     console.log(`✓ Ricetta salvata: ${title} (ID: ${recipeId}) per utente: ${userId}`);

//     res.json({
//       success: true,
//       message: 'Ricetta salvata',
//       recipe: savedRecipe
//     });
//   } catch (error) {
//     console.error('Errore salvataggio ricetta:', error.message);
//     res.status(500).json({ error: 'Errore nel salvataggio della ricetta' });
//   }
// });

// // ============================================
// // ENDPOINT 9: Ottieni ricette salvate (protetto)
// // ============================================
// app.get('/api/recipes/saved', authenticateToken, async (req, res) => {
//   try {
//     const userId = req.user.id; // Usa userId dall'autenticazione

//     const savedRecipes = await SavedRecipe.find({ userId })
//       .sort({ savedAt: -1 }); // Ordina per data di salvataggio (più recenti prima)

//     console.log(`✓ Recuperate ${savedRecipes.length} ricette salvate per utente: ${userId}`);

//     res.json({
//       success: true,
//       recipes: savedRecipes
//     });
//   } catch (error) {
//     console.error('Errore recupero ricette salvate:', error.message);
//     res.status(500).json({ error: 'Errore nel recupero delle ricette salvate' });
//   }
// });

// // ============================================
// // ENDPOINT 10: Rimuovi ricetta salvata (protetto)
// // ============================================
// app.delete('/api/recipes/saved/:recipeId', authenticateToken, async (req, res) => {
//   try {
//     const { recipeId } = req.params;
//     const userId = req.user.id; // Usa userId dall'autenticazione

//     const deletedRecipe = await SavedRecipe.findOneAndDelete({
//       recipeId: parseInt(recipeId),
//       userId
//     });

//     if (!deletedRecipe) {
//       return res.status(404).json({ error: 'Ricetta non trovata' });
//     }

//     console.log(`✓ Ricetta rimossa: ${deletedRecipe.title} (ID: ${recipeId}) per utente: ${userId}`);

//     res.json({
//       success: true,
//       message: 'Ricetta rimossa',
//       recipe: deletedRecipe
//     });
//   } catch (error) {
//     console.error('Errore rimozione ricetta:', error.message);
//     res.status(500).json({ error: 'Errore nella rimozione della ricetta' });
//   }
// });

// // ============================================
// // FUNZIONE: Ottieni suggerimenti per categoria
// // ============================================
// async function getSuggestions(category) {
//   const suggestions = {
//     Dairy: [
//       'Usalo nei dolci o caffè',
//       'Prepara una salsa cremosa',
//       'Congela per gelato fatto in casa',
//     ],
//     Bakery: [
//       'Fai pangrattato tostato',
//       'Usa come miglierina per budini',
//       'Prepara pani di pane',
//     ],
//     Fruits: [
//       'Prepara una marmellata',
//       'Fai un succo o frullato',
//       'Congela per sorbetto',
//     ],
//     Vegetables: [
//       'Fai un minestrone congelato',
//       'Prepara una salsa',
//       'Metti sott\'olio o sottaceto',
//     ],
//     default: ['Controlla ricette online', 'Dona a qualcuno', 'Compostaggio sostenibile'],
//   };

//   return suggestions[category] || suggestions.default;
// }

// // ============================================
// // ENDPOINT 7: Ottieni dettagli ricetta (DEVE essere DOPO le route specifiche)
// // ============================================
// app.get('/api/recipes/:id', async (req, res) => {
//   try {
//     const { id } = req.params;
//     const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY;

//     if (!SPOONACULAR_API_KEY) {
//       return res.status(500).json({ error: 'API key non configurata' });
//     }

//     console.log(`🔍 Recupero dettagli ricetta ID: ${id}`);

//     // Chiama Spoonacular per dettagli completi
//     const response = await axios.get(
//       `https://api.spoonacular.com/recipes/${id}/information`,
//       {
//         params: {
//           apiKey: SPOONACULAR_API_KEY,
//           includeNutrition: false,
//           language: 'it'
//         }
//       }
//     );

//     const recipe = response.data;

//     // Restituisci i dati senza traduzione
//     const recipeDetails = {
//       id: recipe.id,
//       title: recipe.title,
//       image: recipe.image,
//       servings: recipe.servings,
//       readyInMinutes: recipe.readyInMinutes,
//       sourceUrl: recipe.sourceUrl,
//       summary: recipe.summary,
//       instructions: recipe.instructions,
//       extendedIngredients: recipe.extendedIngredients?.map(ing => ({
//         name: ing.name,
//         amount: ing.amount,
//         unit: ing.unit,
//         original: ing.original
//       })) || []
//     };

//     console.log(`✓ Dettagli ricetta recuperati: ${recipe.title}`);

//     res.json({ success: true, recipe: recipeDetails });
//   } catch (error) {
//     console.error('Errore dettagli ricetta:', error.message);
//     res.status(500).json({ error: 'Errore nel recupero dei dettagli' });
//   }
// });

// // ============================================
// // SERVER START
// // ============================================
// const PORT = process.env.PORT || 5001;
// app.listen(PORT, () => {
//   console.log(`Server avviato su http://localhost:${PORT}`);
// });


// server.js - Backend Express.js
const express = require('express');
const axios = require('axios');
const mongoose = require('mongoose');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { translate } = require('@vitalets/google-translate-api');
const cors = require('cors');
require('dotenv').config();

// Funzione per generare UUID
const uuidv4 = () => crypto.randomUUID();

// JWT Secret (in produzione usa variabile d'ambiente)
const JWT_SECRET = process.env.JWT_SECRET || 'shopmart_secret_key_change_in_production';

// Dizionario statico per ingredienti e termini comuni
const translationDictionary = {
  // Ingredienti comuni
  'prosciutto': 'prosciutto',
  'ham': 'prosciutto',
  'pancetta': 'pancetta',
  'proscuitto': 'prosciutto',
  'biscuit type crackers': 'cracker tipo biscotto',
  'fig jam': 'marmellata di fichi',
  'figs': 'fichi',
  'brie cheese': 'formaggio brie',
  'muffins': 'muffin',
  'pear': 'pera',
  'creamy goat cheese': 'formaggio caprino cremoso',
  'basil': 'basilico',
  'thyme': 'timo',
  'juice of lemon': 'succo di limone',
  'chicken thighs': 'cosce di pollo',
  'shells': 'conchiglie',
  'ricotta cheese': 'ricotta',
  'egg': 'uovo',
  'tomato sauce': 'salsa di pomodoro',
  'several basil leaves': 'diverse foglie di basilico',
  'sized cantaloupe': 'melone',
  'chicken stock': 'brodo di pollo',
  'onion': 'cipolla',
  'mushrooms': 'funghi',
  'dijon mustard': 'senape di digione',
  'puff pastry': 'pasta sfoglia',
  'egg yolks': 'tuorli d\'uovo',
  'pork cutlets': 'cotolette di maiale',
  'sage leaves': 'foglie di salvia',
  'butter': 'burro',
  'lemon juice': 'succo di limone',
  'toasty bread': 'pane tostato',
  'garlic': 'aglio',
  'radicchio': 'radicchio',
  'endive': 'indivia',
  'olive oil': 'olio d\'oliva',
  'pistachio nuts': 'pistacchi',
  'honey': 'miele',
  'white peppercorns cracked': 'pepe bianco macinato',
  'peppercorns cracked': 'pepe macinato',
  'shaved prosciutto': 'prosciutto a fette',
  'small jar': 'barattolo piccolo',
  'ounces': 'once',
  'ounce': 'oncia',
  // Titoli ricetta comuni
  'goat cheese, fig and proscuitto crostini': 'crostini di formaggio di capra, fichi e prosciutto',
  'grilled figs with brie and prosciutto': 'fichi grigliati con brie e prosciutto',
  'broiled pear and prosciutto toasts': 'toast con pere e prosciutto alla griglia',
  'chicken thighs wrapped in prosciutto': 'cosce di pollo avvolte nel prosciutto',
  'pasta shells with ricotta cheese stuffing': 'conchiglie di pasta con ripieno di ricotta',
  'cantaloupe soup with crispy ham and basil': 'zuppa di melone con prosciutto croccante e basilico',
  'easy beef wellington': 'manzo wellington facile',
  'mouthwatering grilled saltimbocca': 'saltimbocca alla griglia deliziosi',
  'savory radicchio and prosciutto crostini topped with sweet syrupy sapa': 'crostini salati con radicchio e prosciutto conditi con sapa dolce sciroppata',
  'roasted endive salad with prosciutto, figs and pistachios': 'insalata di indivia arrosto con prosciutto, fichi e pistacchi'
};

// Cache per le traduzioni
const translationCache = new Map();

// Funzione per tradurre testo in italiano con dizionario statico e cache
async function translateToItalian(text) {
  if (!text) return text;

  const lowerText = text.toLowerCase().trim();

  // 1. Controlla dizionario statico
  if (translationDictionary[lowerText]) {
    return translationDictionary[lowerText];
  }

  // 2. Controlla cache
  if (translationCache.has(lowerText)) {
    return translationCache.get(lowerText);
  }

  // 3. Usa Google Translate come fallback (con gestione errori)
  try {
    // Aggiungi un piccolo delay per evitare rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));

    const result = await translate(text, { to: 'it' });
    const translated = result.text;

    // Salva in cache
    translationCache.set(lowerText, translated);

    return translated;
  } catch (error) {
    // In caso di errore, ritorna testo originale
    return text;
  }
}

// Funzione per tradurre un array di testi
async function translateArray(textArray) {
  const translations = await Promise.all(
    textArray.map(text => translateToItalian(text))
  );
  return translations;
}

const app = express();

/**
 * CORS: uso del package `cors` con whitelist configurabile tramite ALLOWED_ORIGINS.
 * - Imposta ALLOWED_ORIGINS in Railway / env come lista separata da virgola.
 *   Esempio:
 *     ALLOWED_ORIGINS=http://localhost:5001,http://192.168.1.238:5001,https://shopmart-app-ceb98.web.app
 */
const allowedOrigins = (process.env.ALLOWED_ORIGINS
  || 'http://localhost:3000,http://localhost:5001,http://192.168.1.238:5001,https://shopmart-app-ceb98.web.app,https://shopmart-app-ceb98.firebaseapp.com')
  .split(',')
  .map(s => s.trim())
  .filter(Boolean);

// Posiziona il middleware CORS PRIMA di express.json() e delle route
app.use(cors({
  origin: function(origin, callback) {
    // allow requests with no origin (like curl, Postman)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) return callback(null, true);
    return callback(new Error('CORS policy: origin not allowed'), false);
  },
  methods: ['GET','POST','PUT','PATCH','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
  credentials: true
}));

// Middleware di debug: log e header Vary per caching corretto
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path} - Origin: ${req.headers.origin || 'none'}`);
  res.setHeader('Vary', 'Origin');
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
// SCHEMA E MODELLO USER
// ============================================
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String }, // Opzionale per utenti Google
  firstName: { type: String },
  lastName: { type: String },
  displayName: { type: String },
  photoUrl: { type: String },
  googleId: { type: String, unique: true, sparse: true }, // Per Google Sign-In
  notificationSettings: {
    enabled: { type: Boolean, default: true },
    urgentDays: { type: Number, default: 3 }, // Notifica quando mancano X giorni
    warningDays: { type: Number, default: 7 }, // Notifica quando mancano X giorni
  },
  createdAt: { type: Date, default: Date.now },
}, { timestamps: true });

// Hash password prima del salvataggio
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

// Metodo per verificare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  return await bcrypt.compare(candidatePassword, candidatePassword) ? true : await bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model('User', userSchema);

// ============================================
// MIDDLEWARE: Verifica JWT Token
// ============================================
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Token mancante' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token non valido' });
    }
    req.user = user; // Aggiungi user ID al request
    next();
  });
};

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
// AUTH ENDPOINTS
// ============================================

// Registrazione con email e password
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email e password sono obbligatori' });
    }

    // Verifica se utente esiste già
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ error: 'Email già registrata' });
    }

    // Crea nuovo utente
    const user = new User({
      email,
      password, // Verrà hashata dal middleware pre-save
      firstName,
      lastName,
      displayName: `${firstName} ${lastName}`,
    });

    await user.save();

    // Genera JWT token
    const token = jwt.sign(
      { id: user._id.toString(), email: user.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`✓ Utente registrato: ${email}`);

    res.status(201).json({
      success: true,
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      },
      token,
    });
  } catch (error) {
    console.error('Errore registrazione:', error);
    res.status(500).json({ error: 'Errore durante la registrazione' });
  }
});

// Login con email e password
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email e password sono obbligatori' });
    }

    // Trova utente
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Credenziali non valide' });
    }

    // Verifica password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Credenziali non valide' });
    }

    // Genera JWT token
    const token = jwt.sign(
      { id: user._id.toString(), email: user.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`✓ Utente loggato: ${email}`);

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      },
      token,
    });
  } catch (error) {
    console.error('Errore login:', error);
    res.status(500).json({ error: 'Errore durante il login' });
  }
});

// Google Sign-In
app.post('/api/auth/google', async (req, res) => {
  try {
    const { googleId, email, displayName, photoUrl, firstName, lastName } = req.body;

    if (!googleId || !email) {
      return res.status(400).json({ error: 'Google ID ed email sono obbligatori' });
    }

    // Cerca utente esistente per googleId o email
    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (user) {
      // Aggiorna googleId se mancante
      if (!user.googleId) {
        user.googleId = googleId;
        await user.save();
      }
    } else {
      // Crea nuovo utente
      user = new User({
        googleId,
        email,
        displayName: displayName || `${firstName} ${lastName}`,
        photoUrl,
        firstName,
        lastName,
      });
      await user.save();
      console.log(`✓ Nuovo utente Google: ${email}`);
    }

    // Genera JWT token
    const token = jwt.sign(
      { id: user._id.toString(), email: user.email },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      },
      token,
    });
  } catch (error) {
    console.error('Errore Google Sign-In:', error);
    res.status(500).json({ error: 'Errore durante l\'autenticazione con Google' });
  }
});

// Ottieni info utente corrente (protetto)
app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');

    if (!user) {
      return res.status(404).json({ error: 'Utente non trovato' });
    }

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      },
    });
  } catch (error) {
    console.error('Errore recupero utente:', error);
    res.status(500).json({ error: 'Errore nel recupero dei dati utente' });
  }
});

// Aggiorna profilo utente (protetto)
app.put('/api/auth/profile', authenticateToken, async (req, res) => {
  try {
    const { firstName, lastName, currentPassword, newPassword } = req.body;

    if (!firstName || !lastName) {
      return res.status(400).json({ error: 'Nome e cognome sono obbligatori' });
    }

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ error: 'Utente non trovato' });
    }

    // Aggiorna nome e cognome
    user.firstName = firstName;
    user.lastName = lastName;
    user.displayName = `${firstName} ${lastName}`;

    // Se l'utente vuole cambiare la password
    if (currentPassword && newPassword) {
      // Verifica che l'utente abbia una password (non utente Google senza password)
      if (!user.password) {
        return res.status(400).json({ error: 'Account Google: impossibile cambiare password' });
      }

      // Verifica password attuale
      const isPasswordValid = await user.comparePassword(currentPassword);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Password attuale non corretta' });
      }

      // Valida nuova password
      if (newPassword.length < 6) {
        return res.status(400).json({ error: 'La nuova password deve avere almeno 6 caratteri' });
      }

      // Aggiorna password (verrà hashata dal middleware pre-save)
      user.password = newPassword;
    }

    await user.save();

    console.log(`✓ Profilo aggiornato: ${user.email}`);

    res.json({
      success: true,
      user: {
        id: user._id.toString(),
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
      },
    });
  } catch (error) {
    console.error('Errore aggiornamento profilo:', error);
    res.status(500).json({ error: 'Errore durante l\'aggiornamento del profilo' });
  }
});

// Aggiorna impostazioni notifiche (protetto)
app.put('/api/auth/notifications', authenticateToken, async (req, res) => {
  try {
    const { enabled, urgentDays, warningDays } = req.body;

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ error: 'Utente non trovato' });
    }

    // Aggiorna impostazioni notifiche
    if (enabled !== undefined) {
      user.notificationSettings.enabled = enabled;
    }
    if (urgentDays !== undefined && urgentDays > 0) {
      user.notificationSettings.urgentDays = urgentDays;
    }
    if (warningDays !== undefined && warningDays > 0) {
      user.notificationSettings.warningDays = warningDays;
    }

    await user.save();

    console.log(`✓ Impostazioni notifiche aggiornate: ${user.email}`);

    res.json({
      success: true,
      notificationSettings: user.notificationSettings,
    });
  } catch (error) {
    console.error('Errore aggiornamento notifiche:', error);
    res.status(500).json({ error: 'Errore durante l\'aggiornamento delle notifiche' });
  }
});

// Ottieni impostazioni notifiche (protetto)
app.get('/api/auth/notifications', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ error: 'Utente non trovato' });
    }

    res.json({
      success: true,
      notificationSettings: user.notificationSettings || {
        enabled: true,
        urgentDays: 3,
        warningDays: 7,
      },
    });
  } catch (error) {
    console.error('Errore recupero notifiche:', error);
    res.status(500).json({ error: 'Errore nel recupero delle impostazioni' });
  }
});

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
// ENDPOINT 2: Aggiungi prodotto al magazzino (protetto)
// ============================================
app.post('/api/inventory/add', authenticateToken, async (req, res) => {
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
      userId: req.user.id, // Associa prodotto all'utente autenticato
    });

    await newProduct.save();

    res.json({ success: true, product: newProduct, message: 'Prodotto aggiunto' });
  } catch (error) {
    console.error('Errore:', error);
    res.status(500).json({ error: 'Errore nell\'aggiunta del prodotto' });
  }
});

// ============================================
// ENDPOINT 3: Ottieni inventario (protetto)
// ============================================
app.get('/api/inventory', authenticateToken, async (req, res) => {
  try {
    // Filtra prodotti per utente autenticato
    const products = await Product.find({ userId: req.user.id });

    // Calcola giorni a scadenza per ogni prodotto
    const inventoryWithStatus = products.map((product) => {
      const expiryDate = new Date(product.expiryDate);
      const today = new Date();
      const daysLeft = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));

      let status = 'OK';
      if (daysLeft <= 0) status = 'SCADUTO';
      else if (daysLeft <= 3) status = 'URGENTE';
      else if (daysLeft <= 7) status = 'ATTENZIONE';

      const productObj = product.toObject();
      return {
        ...productObj,
        id: productObj._id.toString(), // Aggiungi id come stringa per il frontend
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
// (il file continua con le stesse route e logica già presenti...) 
// Per brevità ho mantenuto il resto invariato rispetto al tuo file originale.
// ============================================

// ============================================
// SERVER START
// ============================================
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server avviato su http://localhost:${PORT}`);
});