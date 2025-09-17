// lib/services/reviews_service.dart - FIXED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/review.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addOrUpdateReview({
    required String itemId,
    required int rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // FIXED: Create unique document ID for each user+business combination
    final reviewDocId = '${user.uid}_$itemId';  // e.g., "user123_shop456"
    
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final String userName = userDoc.data()?['name'] ?? 'Anonymous';

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewDocRef);
      final itemSnapshot = await transaction.get(itemDocRef);

      double newRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0.0).toDouble();
      int newReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0);

      // Handle existing review update
      if (reviewSnapshot.exists) {
        final oldRating = (reviewSnapshot.data()?['rating'] ?? 0).toDouble();
        newRatingSum = newRatingSum - oldRating + rating;
      } else {
        // New review
        newReviewCount++;
        newRatingSum += rating;
      }

      // Ensure values are valid
      newRatingSum = newRatingSum < 0 ? 0 : newRatingSum;
      newReviewCount = newReviewCount < 0 ? 0 : newReviewCount;

      // Calculate safe average rating
      double newAverageRating = 0.0;
      if (newReviewCount > 0 && newRatingSum > 0) {
        newAverageRating = newRatingSum / newReviewCount;
        newAverageRating = newAverageRating.clamp(0.0, 5.0);
      }

      // Save review
      transaction.set(reviewDocRef, {
        'itemId': itemId,
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': reviewSnapshot.exists && reviewSnapshot.data()?['createdAt'] != null
            ? reviewSnapshot.data()!['createdAt']
            : FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update item with safe values
      transaction.update(itemDocRef, {
        'averageRating': newAverageRating,
        'ratingSum': newRatingSum,
        'reviewCount': newReviewCount,
      });
    });
  }

  Future<void> deleteReview({
    required String itemId,
    required int rating,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // FIXED: Use same unique document ID format
    final reviewDocId = '${user.uid}_$itemId';
    
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemDocRef);

      double currentRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0.0).toDouble();
      int currentReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0);

      // Calculate new values
      double newRatingSum = (currentRatingSum - rating).clamp(0.0, double.maxFinite);
      int newReviewCount = (currentReviewCount - 1).clamp(0, 999999);

      if (newReviewCount > 0) {
        double newAverageRating = newRatingSum / newReviewCount;
        newAverageRating = newAverageRating.clamp(0.0, 5.0);
        
        transaction.update(itemDocRef, {
          'averageRating': newAverageRating,
          'ratingSum': newRatingSum,
          'reviewCount': newReviewCount,
        });
      } else {
        transaction.update(itemDocRef, {
          'averageRating': 0.0,
          'ratingSum': 0.0,
          'reviewCount': 0,
        });
      }
      
      transaction.delete(reviewDocRef);
    });
  }

  // FIXED: Get user's specific review for a business
  Future<Review?> getUserReviewForItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final reviewDocId = '${user.uid}_$itemId';
    
    try {
      final doc = await _firestore.collection('reviews').doc(reviewDocId).get();
      if (doc.exists) {
        return Review.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<QuerySnapshot> getReviews(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .snapshots();
  }
}