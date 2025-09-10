// models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/models/cart_item_model.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final bool isDelivery;
  final String shopId;
  final String remarks;
  final Timestamp orderDate;
  final String status;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.isDelivery,
    required this.shopId,
    this.remarks = '',
    required this.orderDate,
    required this.status,
  });

  factory Order.fromMap(Map<String, dynamic> data, {required String id}) {
    // This part is crucial for reading from Firestore
    final List<CartItem> items = (data['items'] as List)
        .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return Order(
      id: id,
      userId: data['userId'] as String,
      items: items,
      total: (data['total'] as num).toDouble(),
      isDelivery: data['isDelivery'] as bool,
      shopId: data['shopId'] as String,
      remarks: data['remarks'] as String? ?? '',
      orderDate: data['orderDate'] as Timestamp,
      status: data['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    // This part is crucial for writing to Firestore
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'isDelivery': isDelivery,
      'shopId': shopId,
      'remarks': remarks,
      'orderDate': orderDate,
      'status': status,
    };
  }
}
