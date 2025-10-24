import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class SavedRecipesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<RecipeDetail> _savedRecipes = [];
  bool _isLoading = false;

  List<RecipeDetail> get savedRecipes => _savedRecipes;
  bool get isLoading => _isLoading;

  SavedRecipesProvider() {
    // Non caricare le ricette qui - verranno caricate dopo il login
  }

  // Carica le ricette salvate dal backend
  Future<void> loadSavedRecipes() async {
    try {
      _isLoading = true;
      notifyListeners();

      final recipes = await _apiService.getSavedRecipes();
      _savedRecipes = recipes;

      // If backend returned no recipes (or error), try to load cached recipes
      if (_savedRecipes.isEmpty) {
        debugPrint('⚠️ SavedRecipesProvider: backend returned 0 recipes, attempting to load cache');
        final cached = await _loadCachedRecipes();
        if (cached.isNotEmpty) {
          _savedRecipes = cached;
          debugPrint('✓ Loaded ${_savedRecipes.length} recipes from cache');
        }
      } else {
        // Save to cache the freshly fetched recipes
        await _saveCachedRecipes(_savedRecipes);
        debugPrint('✓ Cached ${_savedRecipes.length} recipes locally');
      }

      _isLoading = false;
      notifyListeners();

      debugPrint('✓ Caricate ${_savedRecipes.length} ricette salvate dal backend');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Errore durante il caricamento delle ricette salvate: $e');
    }
  }

  // Salva una ricetta nel backend
  Future<bool> saveRecipe(RecipeDetail recipe) async {
    try {
      // Controlla se già salvata localmente
      if (_savedRecipes.any((r) => r.id == recipe.id)) {
        debugPrint('⚠️ Ricetta già salvata localmente');
        return false;
      }

      // Salva nel backend
      final success = await _apiService.saveRecipe(recipe);

      if (success) {
        // Aggiungi alla lista locale
        _savedRecipes.insert(0, recipe); // Inserisci in testa (più recente)
        // Aggiorna cache
        await _saveCachedRecipes(_savedRecipes);
        notifyListeners();
        debugPrint('✓ Ricetta salvata: ${recipe.title}');
        return true;
      } else {
        debugPrint('❌ Errore salvataggio ricetta nel backend');
        return false;
      }
    } catch (e) {
      debugPrint('Errore durante il salvataggio della ricetta: $e');
      return false;
    }
  }

  // Rimuovi una ricetta salvata dal backend
  Future<bool> removeRecipe(int recipeId) async {
    try {
      // Rimuovi dal backend
      final success = await _apiService.removeSavedRecipe(recipeId);

      if (success) {
        // Rimuovi dalla lista locale
        _savedRecipes.removeWhere((r) => r.id == recipeId);
        // Aggiorna cache
        await _saveCachedRecipes(_savedRecipes);
        notifyListeners();
        debugPrint('✓ Ricetta rimossa: ID $recipeId');
        return true;
      } else {
        debugPrint('❌ Errore rimozione ricetta dal backend');
        return false;
      }
    } catch (e) {
      debugPrint('Errore durante la rimozione della ricetta: $e');
      return false;
    }
  }

  // --- Local cache helpers (shared_preferences) ---
  static const String _cacheKey = 'saved_recipes_cache_v1';

  Future<void> _saveCachedRecipes(List<RecipeDetail> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = recipes
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'image': r.image,
                'servings': r.servings,
                'readyInMinutes': r.readyInMinutes,
                'sourceUrl': r.sourceUrl,
                'summary': r.summary,
                'instructions': r.instructions,
                'extendedIngredients': r.ingredients
                    .map((ing) => {
                          'name': ing.name,
                          'amount': ing.amount,
                          'unit': ing.unit,
                          'original': ing.original,
                        })
                    .toList(),
              })
          .toList();
      await prefs.setString(_cacheKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Errore salvando cache ricette: $e');
    }
  }

  Future<List<RecipeDetail>> _loadCachedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKey);
      if (str == null) return [];
      final list = jsonDecode(str) as List<dynamic>;
      return list
          .map((item) => RecipeDetail.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Errore caricando cache ricette: $e');
      return [];
    }
  }

  // Controlla se una ricetta è salvata
  bool isRecipeSaved(int recipeId) {
    return _savedRecipes.any((r) => r.id == recipeId);
  }

  // Ricarica le ricette dal backend (refresh manuale)
  Future<void> refresh() async {
    await loadSavedRecipes();
  }
}
