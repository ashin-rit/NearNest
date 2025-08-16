// lib/services/favorites_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get a stream of the current user's favorite items
  Stream<List<String>> getFavoriteItemIds() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Check if an item is a favorite
  Future<bool> isFavorite(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('favorites').doc(itemId).get();
    return doc.exists;
  }

  // Add an item to favorites
  Future<void> addFavorite(String itemId, String itemRole) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('favorites').doc(itemId).set({
      'itemId': itemId,
      'userId': user.uid,
      'itemRole': itemRole,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Remove an item from favorites
  Future<void> removeFavorite(String itemId) async {
    await _firestore.collection('favorites').doc(itemId).delete();
  }
}