import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final int stockQuantity; // New field for stock quantity
  final int minStockLevel; // New field for minimum stock level alert
  final bool isActive; // Renamed from isAvailable - whether product is actively being sold

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stockQuantity,
    this.minStockLevel = 5, // Default minimum stock level
    required this.isActive,
  });

  // Check if product is available for purchase
  bool get isAvailable => isActive && stockQuantity > 0;

  // Check if stock is running low
  bool get isLowStock => stockQuantity <= minStockLevel && stockQuantity > 0;

  // Get stock status for display
  String get stockStatus {
    if (!isActive) return 'Inactive';
    if (stockQuantity <= 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock ($stockQuantity left)';
    return 'In Stock ($stockQuantity available)';
  }

  // Get stock status color
  String get stockStatusColor {
    if (!isActive) return 'grey';
    if (stockQuantity <= 0) return 'red';
    if (isLowStock) return 'orange';
    return 'green';
  }

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
      category: data['category'] ?? 'Uncategorized',
      stockQuantity: data['stockQuantity'] ?? 0,
      minStockLevel: data['minStockLevel'] ?? 5,
      // For backward compatibility, check both new 'isActive' and old 'isAvailable'
      isActive: data['isActive'] ?? data['isAvailable'] ?? true,
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
      'stockQuantity': stockQuantity,
      'minStockLevel': minStockLevel,
      'isActive': isActive,
      // Keep the old field for backward compatibility
      'isAvailable': isActive && stockQuantity > 0,
    };
  }

  // Method to create a copy with updated values
  Product copyWith({
    String? id,
    String? shopId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    int? stockQuantity,
    int? minStockLevel,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      isActive: isActive ?? this.isActive,
    );
  }

  // Method to reduce stock when an order is placed
  Product reduceStock(int quantity) {
    final newQuantity = (stockQuantity - quantity).clamp(0, stockQuantity);
    return copyWith(stockQuantity: newQuantity);
  }

  // Method to increase stock when restocking
  Product increaseStock(int quantity) {
    return copyWith(stockQuantity: stockQuantity + quantity);
  }
}