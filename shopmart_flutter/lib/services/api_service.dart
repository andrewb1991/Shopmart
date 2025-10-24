import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  static String get baseUrl => AppConfig.apiUrl;

  // Ottieni headers con token JWT
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    print('🔐 ApiService: token present=${token != null}');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Cerca prodotto per barcode
  Future<Product?> lookupProduct(String barcode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/product/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['product'] != null) {
          return Product.fromJson(data['product']);
        }
      }
      return null;
    } catch (e) {
      print('Errore durante la ricerca del prodotto: $e');
      return null;
    }
  }

  // Ottieni inventario
  Future<List<InventoryItem>> getInventory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] != null) {
          return (data['products'] as List)
              .map((item) => InventoryItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore durante il caricamento dell\'inventario: $e');
      return [];
    }
  }

  // Aggiungi prodotto all'inventario
  Future<bool> addToInventory({
    required Product product,
    required int quantity,
    required DateTime expiryDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/add'),
        headers: headers,
        body: jsonEncode({
          'barcode': product.barcode,
          'productName': product.productName,
          'brand': product.brand,
          'category': product.category,
          'quantity': quantity,
          'unit': product.unit,
          'expiryDate': expiryDate.toIso8601String(),
          'ingredients': product.ingredients,
          'nutritionInfo': product.nutritionInfo,
          'imageUrl': product.imageUrl,
          'suggestions': [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Errore durante l\'aggiunta del prodotto: $e');
      return false;
    }
  }

  // Elimina prodotto dall'inventario
  Future<bool> deleteFromInventory(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/inventory/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Errore durante l\'eliminazione del prodotto: $e');
      return false;
    }
  }

  // Aggiorna quantità prodotto
  Future<bool> updateQuantity(String id, int newQuantity) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/inventory/$id/quantity'),
        headers: headers,
        body: jsonEncode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Errore durante l\'aggiornamento della quantità: $e');
      return false;
    }
  }

  // Aggiorna prodotto completo
  Future<bool> updateProduct({
    required String id,
    required String productName,
    required String brand,
    required int quantity,
    required String unit,
    required DateTime expiryDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/inventory/$id'),
        headers: headers,
        body: jsonEncode({
          'productName': productName,
          'brand': brand,
          'quantity': quantity,
          'unit': unit,
          'expiryDate': expiryDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Errore durante l\'aggiornamento del prodotto: $e');
      return false;
    }
  }

  // Suggerisci ricette basate su ingredienti
  Future<List<Recipe>> suggestRecipes(List<String> ingredients) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': ingredients}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['recipes'] != null) {
          return (data['recipes'] as List)
              .map((recipe) => Recipe.fromJson(recipe))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore durante la ricerca delle ricette: $e');
      return [];
    }
  }

  // Ottieni dettagli ricetta
  Future<RecipeDetail?> getRecipeDetails(int recipeId) async {
    try {
      print('📡 Chiamata API: $baseUrl/recipes/$recipeId');
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/$recipeId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 Data success: ${data['success']}');
        print('📡 Recipe null? ${data['recipe'] == null}');

        if (data['success'] == true && data['recipe'] != null) {
          print('📡 Parsing JSON...');
          final recipeDetail = RecipeDetail.fromJson(data['recipe']);
          print('📡 Parsing completato: ${recipeDetail.title}');
          return recipeDetail;
        }
      }
      print('❌ Nessun dato valido');
      return null;
    } catch (e, stackTrace) {
      print('❌ Errore durante il caricamento dei dettagli della ricetta: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // Salva ricetta nel backend
  Future<bool> saveRecipe(RecipeDetail recipe) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/save'),
        headers: headers,
        body: jsonEncode({
          'recipeId': recipe.id,
          'title': recipe.title,
          'image': recipe.image,
          'servings': recipe.servings,
          'readyInMinutes': recipe.readyInMinutes,
          'sourceUrl': recipe.sourceUrl,
          'summary': recipe.summary,
          'instructions': recipe.instructions,
          'ingredients': recipe.ingredients
              .map((ing) => {
                    'name': ing.name,
                    'amount': ing.amount,
                    'unit': ing.unit,
                    'original': ing.original,
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      // 409 = già salvata, consideriamo come successo
      if (response.statusCode == 409) {
        return true;
      }
      return false;
    } catch (e) {
      print('Errore durante il salvataggio della ricetta: $e');
      return false;
    }
  }

  // Ottieni ricette salvate dal backend
  Future<List<RecipeDetail>> getSavedRecipes() async {
    try {
      final headers = await _getHeaders();
      print('📡 ApiService.getSavedRecipes: headers=$headers');
      final response = await http.get(
        Uri.parse('$baseUrl/recipes/saved'),
        headers: headers,
      );

      print('📡 ApiService.getSavedRecipes: status=${response.statusCode} body=${response.body.length}');
      if (response.statusCode != 200) {
        print('📡 ApiService.getSavedRecipes: response body=${response.body}');
      } else {
        // Also log body on success for debugging (trim if large)
        final bodyStr = response.body;
        print('📡 ApiService.getSavedRecipes: response body (trim)=${bodyStr.length > 1000 ? bodyStr.substring(0, 1000) + "..." : bodyStr}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['recipes'] != null) {
          return (data['recipes'] as List)
              .map((recipe) => RecipeDetail.fromJson({
                    'id': recipe['recipeId'],
                    'title': recipe['title'],
                    'image': recipe['image'],
                    'servings': recipe['servings'],
                    'readyInMinutes': recipe['readyInMinutes'],
                    'sourceUrl': recipe['sourceUrl'],
                    'summary': recipe['summary'],
                    'instructions': recipe['instructions'],
                    'extendedIngredients': recipe['ingredients'],
                  }))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Errore durante il recupero delle ricette salvate: $e');
      return [];
    }
  }

  // Rimuovi ricetta dal backend
  Future<bool> removeSavedRecipe(int recipeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/recipes/saved/$recipeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Errore durante la rimozione della ricetta: $e');
      return false;
    }
  }
}

// Model per ricetta base
class Recipe {
  final int id;
  final String title;
  final String? image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> usedIngredients;
  final List<String> missedIngredients;

  Recipe({
    required this.id,
    required this.title,
    this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.usedIngredients,
    required this.missedIngredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
      usedIngredients: (json['usedIngredients'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      missedIngredients: (json['missedIngredients'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// Model per dettaglio ricetta
class RecipeDetail {
  final int id;
  final String title;
  final String? image;
  final int? servings;
  final int? readyInMinutes;
  final String? sourceUrl;
  final String? summary;
  final String? instructions;
  final List<RecipeIngredient> ingredients;

  RecipeDetail({
    required this.id,
    required this.title,
    this.image,
    this.servings,
    this.readyInMinutes,
    this.sourceUrl,
    this.summary,
    this.instructions,
    required this.ingredients,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      servings: json['servings'],
      readyInMinutes: json['readyInMinutes'],
      sourceUrl: json['sourceUrl'],
      summary: json['summary'],
      instructions: json['instructions'],
      ingredients: (json['extendedIngredients'] as List?)
              ?.map((e) => RecipeIngredient.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Model per ingrediente ricetta
class RecipeIngredient {
  final String name;
  final double? amount;
  final String? unit;
  final String original;

  RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
    required this.original,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble(),
      unit: json['unit'],
      original: json['original'] ?? '',
    );
  }
}
