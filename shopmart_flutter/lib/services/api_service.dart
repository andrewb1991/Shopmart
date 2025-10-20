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
}
