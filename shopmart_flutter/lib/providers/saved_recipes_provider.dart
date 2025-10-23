import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SavedRecipesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<RecipeDetail> _savedRecipes = [];
  bool _isLoading = false;

  List<RecipeDetail> get savedRecipes => _savedRecipes;
  bool get isLoading => _isLoading;

  SavedRecipesProvider() {
    loadSavedRecipes();
  }

  // Carica le ricette salvate dal backend
  Future<void> loadSavedRecipes() async {
    try {
      _isLoading = true;
      notifyListeners();

      final recipes = await _apiService.getSavedRecipes();
      _savedRecipes = recipes;

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

  // Controlla se una ricetta è salvata
  bool isRecipeSaved(int recipeId) {
    return _savedRecipes.any((r) => r.id == recipeId);
  }

  // Ricarica le ricette dal backend (refresh manuale)
  Future<void> refresh() async {
    await loadSavedRecipes();
  }
}
