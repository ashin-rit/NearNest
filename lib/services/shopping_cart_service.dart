// lib/services/shopping_cart_service.dart
import 'package:flutter/material.dart';
import 'package:nearnest/models/product_model.dart';

class ShoppingCartService with ChangeNotifier {
  final Map<String, Product> _items = {};

  Map<String, Product> get items => _items;

  double get total {
    return _items.values.fold(0, (sum, item) => sum + item.price);
  }

  void addItem(Product product) {
    // For simplicity, we assume one product per add.
    // You can modify this to handle quantities.
    if (_items.containsKey(product.id)) {
      // You can implement logic to increase quantity here
    } else {
      _items[product.id] = product;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}