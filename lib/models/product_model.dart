import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category; // New field for product category
  final bool isAvailable; // New field to track availability

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
  });

  // Factory constructor to create a Product object from a Firestore document snapshot.
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'Uncategorized', // Providing a default category
      isAvailable: data['isAvailable'] ?? true, // Providing a default availability status
    );
  }

  // Method to convert a Product object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
    };
  }
}
