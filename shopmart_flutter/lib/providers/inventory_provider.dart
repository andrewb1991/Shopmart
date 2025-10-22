import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<InventoryItem> _inventory = [];
  bool _isLoading = false;
  Product? _currentProduct;
  String? _errorMessage;

  List<InventoryItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
  Product? get currentProduct => _currentProduct;
  String? get errorMessage => _errorMessage;

  // Carica inventario
  Future<void> loadInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inventory = await _apiService.getInventory();
      // Ordina per data di scadenza (prima i prodotti in scadenza)
      _inventory.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
      debugPrint('✅ Inventario caricato: ${_inventory.length} prodotti');
    } catch (e) {
      _errorMessage = 'Errore nel caricamento dell\'inventario';
      _inventory = []; // Assicurati che la lista sia vuota in caso di errore
      debugPrint('⚠️ Errore caricamento inventario: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cerca prodotto per barcode
  Future<bool> lookupProduct(String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    _currentProduct = null;
    notifyListeners();

    try {
      final product = await _apiService.lookupProduct(barcode);
      if (product != null) {
        _currentProduct = product;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Prodotto non trovato';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Errore nella ricerca del prodotto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Aggiungi prodotto all'inventario
  Future<bool> addProduct({
    required Product product,
    required int quantity,
    required DateTime expiryDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.addToInventory(
        product: product,
        quantity: quantity,
        expiryDate: expiryDate,
      );

      if (success) {
        await loadInventory();
        _currentProduct = null;
        return true;
      } else {
        _errorMessage = 'Errore nell\'aggiunta del prodotto';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Errore nell\'aggiunta del prodotto';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Elimina prodotto dall'inventario
  Future<bool> deleteProduct(String id) async {
    try {
      final success = await _apiService.deleteFromInventory(id);
      if (success) {
        await loadInventory();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Errore nell\'eliminazione del prodotto';
      notifyListeners();
      return false;
    }
  }

  // Aggiorna quantità prodotto
  Future<bool> updateQuantity(String id, int newQuantity) async {
    if (newQuantity < 0) return false;

    try {
      final success = await _apiService.updateQuantity(id, newQuantity);
      if (success) {
        // Aggiorna solo l'item specifico localmente per una risposta più veloce
        final index = _inventory.indexWhere((item) => item.id == id);
        if (index != -1) {
          // Ricrea l'item con la nuova quantità
          final item = _inventory[index];
          _inventory[index] = InventoryItem(
            id: item.id,
            barcode: item.barcode,
            productName: item.productName,
            brand: item.brand,
            category: item.category,
            quantity: newQuantity,
            unit: item.unit,
            expiryDate: item.expiryDate,
            ingredients: item.ingredients,
            nutritionInfo: item.nutritionInfo,
            imageUrl: item.imageUrl,
            status: item.status,
            daysLeft: item.daysLeft,
            suggestions: item.suggestions,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Errore nell\'aggiornamento della quantità';
      notifyListeners();
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
      final success = await _apiService.updateProduct(
        id: id,
        productName: productName,
        brand: brand,
        quantity: quantity,
        unit: unit,
        expiryDate: expiryDate,
      );

      if (success) {
        // Ricarica l'inventario per ottenere i dati aggiornati (incluso il nuovo status)
        await loadInventory();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Errore nell\'aggiornamento del prodotto';
      notifyListeners();
      return false;
    }
  }

  // Reset del prodotto corrente
  void clearCurrentProduct() {
    _currentProduct = null;
    notifyListeners();
  }

  // Reset errore
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
