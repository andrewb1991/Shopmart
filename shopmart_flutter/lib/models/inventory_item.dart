import 'product.dart';

enum ProductStatus {
  ok,
  attenzione,
  urgente,
  scaduto,
}

class InventoryItem {
  final String id;
  final String barcode;
  final String productName;
  final String brand;
  final String? category;
  final int quantity;
  final String? unit;
  final DateTime expiryDate;
  final String? ingredients;
  final Map<String, dynamic>? nutritionInfo;
  final String? imageUrl;
  final ProductStatus status;
  final int daysLeft;
  final List<String> suggestions;

  InventoryItem({
    required this.id,
    required this.barcode,
    required this.productName,
    required this.brand,
    this.category,
    required this.quantity,
    this.unit,
    required this.expiryDate,
    this.ingredients,
    this.nutritionInfo,
    this.imageUrl,
    required this.status,
    required this.daysLeft,
    this.suggestions = const [],
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? json['_id'] ?? '',
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'],
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
      expiryDate: DateTime.parse(json['expiryDate']),
      ingredients: json['ingredients'],
      nutritionInfo: json['nutritionInfo'],
      imageUrl: json['imageUrl'],
      status: _parseStatus(json['status']),
      daysLeft: json['daysLeft'] ?? 0,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static ProductStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCADUTO':
        return ProductStatus.scaduto;
      case 'URGENTE':
        return ProductStatus.urgente;
      case 'ATTENZIONE':
        return ProductStatus.attenzione;
      default:
        return ProductStatus.ok;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': expiryDate.toIso8601String(),
      'ingredients': ingredients,
      'nutritionInfo': nutritionInfo,
      'imageUrl': imageUrl,
      'status': status.name.toUpperCase(),
      'daysLeft': daysLeft,
      'suggestions': suggestions,
    };
  }

  Product toProduct() {
    return Product(
      barcode: barcode,
      productName: productName,
      brand: brand,
      category: category,
      unit: unit,
      ingredients: ingredients,
      nutritionInfo: nutritionInfo,
      imageUrl: imageUrl,
    );
  }
}
