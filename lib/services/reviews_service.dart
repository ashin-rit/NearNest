// lib/services/reviews_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a review and update the shop's average rating
  Future<void> addReview({
    required String itemId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final reviewDocRef = _firestore.collection('reviews').doc();
    final itemDocRef = _firestore.collection('users').doc(itemId);

    // Run a batched write to ensure both operations succeed or fail together
    WriteBatch batch = _firestore.batch();

    // 1. Add the new review document
    batch.set(reviewDocRef, {
      'itemId': itemId,
      'userId': user.uid,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Get the current average rating and count to update them
    final itemDoc = await itemDocRef.get();
    final currentRating = itemDoc.get('averageRating') ?? 0.0;
    final currentReviewCount = itemDoc.get('reviewCount') ?? 0;

    final newReviewCount = currentReviewCount + 1;
    final newAverageRating =
        (currentRating * currentReviewCount + rating) / newReviewCount;

    // 3. Update the shop/service document with the new rating
    batch.update(itemDocRef, {
      'averageRating': newAverageRating,
      'reviewCount': newReviewCount,
    });

    // Commit the batch
    await batch.commit();
  }

  // Get a stream of reviews for a specific shop/service
  Stream<QuerySnapshot> getReviews(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}