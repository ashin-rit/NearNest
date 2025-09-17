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

  // Get items grouped by shop
  Map<String, List<CartItem>> get itemsByShop {
    Map<String, List<CartItem>> grouped = {};
    for (CartItem item in _items.values) {
      if (!grouped.containsKey(item.shopId)) {
        grouped[item.shopId] = [];
      }
      grouped[item.shopId]!.add(item);
    }
    return grouped;
  }

  // Get unique shop IDs in cart
  List<String> get shopIds => itemsByShop.keys.toList();

  // Get total amount for a specific shop
  double getTotalForShop(String shopId) {
    return _items.values
        .where((item) => item.shopId == shopId)
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Get item count for a specific shop
  int getItemCountForShop(String shopId) {
    return _items.values.where((item) => item.shopId == shopId).length;
  }

  // Get total item count across all shops
  int get itemCount => _items.length;

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

  // Remove all items from a specific shop
  Future<void> clearShopItems(String shopId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    
    // Get items to remove from this shop
    final itemsToRemove = _items.entries
        .where((entry) => entry.value.shopId == shopId)
        .map((entry) => entry.key)
        .toList();

    // Remove from local state
    for (String productId in itemsToRemove) {
      _items.remove(productId);
    }

    // Remove from Firestore
    final batch = FirebaseFirestore.instance.batch();
    for (String productId in itemsToRemove) {
      batch.delete(cartRef.doc(productId));
    }
    await batch.commit();

    notifyListeners();
  }

  Future<void> clearCart() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    final snapshot = await cartRef.get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    _items.clear();
    notifyListeners();
  }

  // Update item quantity directly
  Future<void> updateItemQuantity(String productId, int quantity) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || !_items.containsKey(productId)) {
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    
    if (quantity <= 0) {
      _items.remove(productId);
      await cartRef.doc(productId).delete();
    } else {
      final existingItem = _items[productId]!;
      final updatedItem = CartItem(
        id: existingItem.id,
        name: existingItem.name,
        price: existingItem.price,
        quantity: quantity,
        imageUrl: existingItem.imageUrl,
        shopId: existingItem.shopId,
      );
      _items[productId] = updatedItem;
      await cartRef.doc(productId).update({'quantity': quantity});
    }
    notifyListeners();
  }

  // Remove specific item completely
  Future<void> removeItem(String productId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || !_items.containsKey(productId)) {
      return;
    }

    final cartRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
    
    _items.remove(productId);
    await cartRef.doc(productId).delete();
    notifyListeners();
  }

  // Check if product is in cart
  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  // Get quantity of specific item
  int getItemQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }
}