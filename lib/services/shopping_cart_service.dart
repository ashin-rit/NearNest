import 'package:flutter/material.dart';
import 'package:nearnest/models/cart_item_model.dart';
import 'package:nearnest/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingCartService with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> fetchCartItems() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _items.clear();
      notifyListeners();
      return;
    }
    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
      final snapshot = await cartRef.get();
      _items.clear();
      for (var doc in snapshot.docs) {
        _items[doc.id] = CartItem.fromMap(doc.data());
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching cart items: $e');
    }
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Return early if the user is not logged in.
      return;
    }
    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    
    if (_items.containsKey(product.id)) {
      final existingItem = _items[product.id]!;
      final newQuantity = existingItem.quantity + quantity;
      final updatedItem = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        quantity: newQuantity,
        imageUrl: existingItem.imageUrl,
        shopId: existingItem.shopId,
      );
      _items[product.id] = updatedItem;
      await cartRef.doc(product.id).update({'quantity': newQuantity});
    } else {
      final newItem = CartItem.fromProduct(product, quantity);
      _items[product.id] = newItem;
      await cartRef.doc(product.id).set(newItem.toMap());
    }
    notifyListeners();
  }

  Future<void> removeSingleItem(String productId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || !_items.containsKey(productId)) {
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    final existingItem = _items[productId]!;

    if (existingItem.quantity > 1) {
      final newQuantity = existingItem.quantity - 1;
      final updatedItem = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        quantity: newQuantity,
        imageUrl: existingItem.imageUrl,
        shopId: existingItem.shopId,
      );
      _items[productId] = updatedItem;
      await cartRef.doc(productId).update({'quantity': newQuantity});
    } else {
      _items.remove(productId);
      await cartRef.doc(productId).delete();
    }
    notifyListeners();
  }

  Future<void> clearCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    final snapshot = await cartRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    _items.clear();
    notifyListeners();
  }
}
