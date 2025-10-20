import 'package:flutter/foundation.dart';
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
    } catch (e) {
      _errorMessage = 'Errore nel caricamento dell\'inventario';
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
