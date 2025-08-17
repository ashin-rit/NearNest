// lib/services/favorites_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a reference to the user's favorite collection
  CollectionReference<Map<String, dynamic>> _favoritesCollection() {
    final userId = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Add a shop or service to favorites
  Future<void> addFavorite(String itemId, String role) async {
    await _favoritesCollection().doc(itemId).set({
      'itemId': itemId,
      'role': role,
      'favoritedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a shop or service from favorites
  Future<void> removeFavorite(String itemId) async {
    await _favoritesCollection().doc(itemId).delete();
  }

  // Check if an item is already a favorite
  Future<bool> isFavorite(String itemId) async {
    final doc = await _favoritesCollection().doc(itemId).get();
    return doc.exists;
  }

  // Get a stream of favorite item IDs for the current user
  Stream<List<String>> getFavoriteItemIds() {
    return _favoritesCollection().snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }
}