// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/models/cart_item_model.dart'; // Changed to use CartItem
import 'package:nearnest/models/product_model.dart';

class Order {
  final String id;
  final String userId;
  final String shopId;
  final List<CartItem> items; // Changed to use CartItem
  final double total;
  final bool isDelivery;
  final Map<String, dynamic>? deliveryAddress;
  final String? remarks; // Added remarks field
  final Timestamp orderDate;
  final String status;

  Order({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.items,
    required this.total,
    required this.isDelivery,
    this.deliveryAddress,
    this.remarks, // Added to constructor
    required this.orderDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shopId': shopId,
      'items': items.map((item) => {
            'id': item.id,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'imageUrl': item.imageUrl,
          }).toList(),
      'total': total,
      'isDelivery': isDelivery,
      'deliveryAddress': deliveryAddress,
      'remarks': remarks, // Added to map
      'orderDate': orderDate,
      'status': status,
    };
  }
}
