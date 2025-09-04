import 'package:nearnest/models/product_model.dart';

class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;
  final String shopId;

  const CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    required this.shopId,
  });

  // A helper method to create a new CartItem instance with updated values.
  CartItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? price,
    String? imageUrl,
    String? shopId,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      shopId: shopId ?? this.shopId,
    );
  }

  // Converts a CartItem instance to a Map, which can be stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'shopId': shopId,
    };
  }

  // Creates a CartItem instance from a Product, useful when adding a new item.
  factory CartItem.fromProduct(Product product, int quantity) {
    return CartItem(
      id: product.id,
      name: product.name,
      price: product.price,
      quantity: quantity,
      imageUrl: product.imageUrl,
      shopId: product.shopId,
    );
  }

  // Creates a CartItem instance from a Firestore document's Map.
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      // Safely convert Firestore's number type (int or double) to a double.
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      shopId: map['shopId'] as String,
    );
  }
}
