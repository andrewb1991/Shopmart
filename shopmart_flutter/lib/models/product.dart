class Product {
  final String barcode;
  final String productName;
  final String brand;
  final String? category;
  final String? unit;
  final String? ingredients;
  final Map<String, dynamic>? nutritionInfo;
  final String? imageUrl;

  Product({
    required this.barcode,
    required this.productName,
    required this.brand,
    this.category,
    this.unit,
    this.ingredients,
    this.nutritionInfo,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'],
      unit: json['unit'],
      ingredients: json['ingredients'],
      nutritionInfo: json['nutritionInfo'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'category': category,
      'unit': unit,
      'ingredients': ingredients,
      'nutritionInfo': nutritionInfo,
      'imageUrl': imageUrl,
    };
  }
}
