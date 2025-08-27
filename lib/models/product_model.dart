// lib/models/product_model.dart
class Product {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'],
      shopId: data['shopId'],
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  // New method to convert a Product object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}