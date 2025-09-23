// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/models/cart_item_model.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validates if the requested quantities are available in stock
  Future<Map<String, dynamic>> validateStock(List<CartItem> items) async {
    try {
      final Map<String, dynamic> result = {
        'isValid': true,
        'errors': <String>[],
        'warnings': <String>[],
        'unavailableItems': <CartItem>[],
        'lowStockItems': <CartItem>[],
      };

      for (CartItem item in items) {
        final productDoc = await _firestore
            .collection('products')
            .doc(item.id)
            .get();

        if (!productDoc.exists) {
          result['isValid'] = false;
          result['errors'].add('Product "${item.name}" no longer exists');
          result['unavailableItems'].add(item);
          continue;
        }

        final data = productDoc.data() as Map<String, dynamic>;
        final stockQuantity = data['stockQuantity'] ?? 0;
        final isActive = data['isActive'] ?? data['isAvailable'] ?? true;
        final minStockLevel = data['minStockLevel'] ?? 5;

        if (!isActive) {
          result['isValid'] = false;
          result['errors'].add('Product "${item.name}" is no longer available');
          result['unavailableItems'].add(item);
          continue;
        }

        if (stockQuantity < item.quantity) {
          result['isValid'] = false;
          if (stockQuantity <= 0) {
            result['errors'].add('Product "${item.name}" is out of stock');
          } else {
            result['errors'].add(
              'Only ${stockQuantity} units of "${item.name}" available (requested ${item.quantity})'
            );
          }
          result['unavailableItems'].add(item);
          continue;
        }

        // Check if purchase will result in low stock
        if (stockQuantity - item.quantity <= minStockLevel && 
            stockQuantity - item.quantity > 0) {
          result['warnings'].add(
            'Low stock warning for "${item.name}" after this purchase'
          );
          result['lowStockItems'].add(item);
        }
      }

      return result;
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Error validating stock: ${e.toString()}'],
        'warnings': <String>[],
        'unavailableItems': <CartItem>[],
        'lowStockItems': <CartItem>[],
      };
    }
  }

  /// Reduces stock quantities for the given items
  Future<bool> reduceStock(List<CartItem> items, String orderId) async {
    try {
      // Use a batch operation to ensure atomicity
      WriteBatch batch = _firestore.batch();
      
      for (CartItem item in items) {
        final productRef = _firestore.collection('products').doc(item.id);
        
        // Get current stock
        final productDoc = await productRef.get();
        if (!productDoc.exists) {
          throw Exception('Product ${item.name} not found');
        }
        
        final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
        final newStock = (currentStock - item.quantity).clamp(0, currentStock);
        
        // Update stock and add transaction log
        batch.update(productRef, {
          'stockQuantity': newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isAvailable': newStock > 0 && (productDoc.data()?['isActive'] ?? true),
        });

        // Log the stock reduction for audit trail
        batch.set(_firestore.collection('stock_transactions').doc(), {
          'productId': item.id,
          'productName': item.name,
          'type': 'sale',
          'quantityChanged': -item.quantity,
          'previousStock': currentStock,
          'newStock': newStock,
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error reducing stock: $e');
      return false;
    }
  }

  /// Restores stock quantities (used when orders are cancelled)
  Future<bool> restoreStock(List<CartItem> items, String orderId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (CartItem item in items) {
        final productRef = _firestore.collection('products').doc(item.id);
        
        // Get current stock
        final productDoc = await productRef.get();
        if (!productDoc.exists) {
          continue; // Skip if product was deleted
        }
        
        final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
        final newStock = currentStock + item.quantity;
        
        // Restore stock
        batch.update(productRef, {
          'stockQuantity': newStock,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isAvailable': newStock > 0 && (productDoc.data()?['isActive'] ?? true),
        });

        // Log the stock restoration
        batch.set(_firestore.collection('stock_transactions').doc(), {
          'productId': item.id,
          'productName': item.name,
          'type': 'restoration',
          'quantityChanged': item.quantity,
          'previousStock': currentStock,
          'newStock': newStock,
          'orderId': orderId,
          'reason': 'Order cancellation',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error restoring stock: $e');
      return false;
    }
  }

  /// Checks if a specific product has sufficient stock
  Future<Map<String, dynamic>> checkProductStock(String productId, int requiredQuantity) async {
    try {
      final productDoc = await _firestore.collection('products').doc(productId).get();
      
      if (!productDoc.exists) {
        return {
          'available': false,
          'reason': 'Product not found',
          'currentStock': 0,
          'maxAvailable': 0,
        };
      }

      final data = productDoc.data() as Map<String, dynamic>;
      final stockQuantity = data['stockQuantity'] ?? 0;
      final isActive = data['isActive'] ?? data['isAvailable'] ?? true;

      if (!isActive) {
        return {
          'available': false,
          'reason': 'Product is inactive',
          'currentStock': stockQuantity,
          'maxAvailable': 0,
        };
      }

      if (stockQuantity >= requiredQuantity) {
        return {
          'available': true,
          'reason': 'Stock available',
          'currentStock': stockQuantity,
          'maxAvailable': stockQuantity,
        };
      } else {
        return {
          'available': false,
          'reason': stockQuantity > 0 ? 'Insufficient stock' : 'Out of stock',
          'currentStock': stockQuantity,
          'maxAvailable': stockQuantity,
        };
      }
    } catch (e) {
      return {
        'available': false,
        'reason': 'Error checking stock: ${e.toString()}',
        'currentStock': 0,
        'maxAvailable': 0,
      };
    }
  }

  /// Gets low stock products for a shop
  Future<List<Map<String, dynamic>>> getLowStockProducts(String shopId) async {
    try {
      final query = await _firestore
          .collection('products')
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> lowStockProducts = [];
      
      for (var doc in query.docs) {
        final data = doc.data();
        final stockQuantity = data['stockQuantity'] ?? 0;
        final minStockLevel = data['minStockLevel'] ?? 5;
        
        if (stockQuantity <= minStockLevel) {
          lowStockProducts.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'currentStock': stockQuantity,
            'minStockLevel': minStockLevel,
            'category': data['category'] ?? 'Uncategorized',
            'price': data['price'] ?? 0.0,
            'isOutOfStock': stockQuantity <= 0,
          });
        }
      }
      
      // Sort by urgency (out of stock first, then by stock level)
      lowStockProducts.sort((a, b) {
        if (a['isOutOfStock'] && !b['isOutOfStock']) return -1;
        if (!a['isOutOfStock'] && b['isOutOfStock']) return 1;
        return a['currentStock'].compareTo(b['currentStock']);
      });
      
      return lowStockProducts;
    } catch (e) {
      print('Error getting low stock products: $e');
      return [];
    }
  }

  /// Gets stock transaction history for a product
  Future<List<Map<String, dynamic>>> getStockHistory(String productId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('stock_transactions')
          .where('productId', isEqualTo: productId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown',
          'quantityChanged': data['quantityChanged'] ?? 0,
          'previousStock': data['previousStock'] ?? 0,
          'newStock': data['newStock'] ?? 0,
          'orderId': data['orderId'],
          'reason': data['reason'],
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error getting stock history: $e');
      return [];
    }
  }

  /// Bulk update stock for multiple products
  Future<bool> bulkUpdateStock(Map<String, int> productStockUpdates, String reason) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String productId in productStockUpdates.keys) {
        final newStock = productStockUpdates[productId]!;
        final productRef = _firestore.collection('products').doc(productId);
        
        // Get current data to log the change
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final currentStock = productDoc.data()?['stockQuantity'] ?? 0;
          final productName = productDoc.data()?['name'] ?? 'Unknown';
          final isActive = productDoc.data()?['isActive'] ?? true;
          
          batch.update(productRef, {
            'stockQuantity': newStock,
            'lastUpdated': FieldValue.serverTimestamp(),
            'isAvailable': newStock > 0 && isActive,
          });

          // Log the bulk update
          batch.set(_firestore.collection('stock_transactions').doc(), {
            'productId': productId,
            'productName': productName,
            'type': 'bulk_update',
            'quantityChanged': newStock - currentStock,
            'previousStock': currentStock,
            'newStock': newStock,
            'reason': reason,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Error in bulk stock update: $e');
      return false;
    }
  }
}