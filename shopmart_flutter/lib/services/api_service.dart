import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';

class ApiService {
  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://localhost:5001/api';

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
      final response = await http.get(
        Uri.parse('$baseUrl/inventory'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/add'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.delete(
        Uri.parse('$baseUrl/inventory/$id'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.patch(
        Uri.parse('$baseUrl/inventory/$id/quantity'),
        headers: {'Content-Type': 'application/json'},
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
      final response = await http.patch(
        Uri.parse('$baseUrl/inventory/$id'),
        headers: {'Content-Type': 'application/json'},
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
          .toList() ?? [],
      missedIngredients: (json['missedIngredients'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
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
          .toList() ?? [],
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
