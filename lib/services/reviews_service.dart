// lib/services/reviews_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/review.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addOrUpdateReview({
    required String itemId,
    required String reviewDocId,
    required int rating,
    required String comment,
    required FieldValue lastUpdated,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewDocRef);
      final itemSnapshot = await transaction.get(itemDocRef);

      double newRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0).toDouble();
      int newReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0);

      if (reviewSnapshot.exists) {
        final oldRating = (reviewSnapshot.data()?['rating'] ?? 0).toDouble();
        newRatingSum -= oldRating;
      } else {
        newReviewCount++;
      }

      newRatingSum += rating;

      transaction.set(reviewDocRef, {
        'itemId': itemId,
        'userId': user.uid,
        'rating': rating,
        'comment': comment,
        'createdAt': reviewSnapshot.exists && reviewSnapshot.data()?['createdAt'] != null
            ? reviewSnapshot.data()!['createdAt']
            : FieldValue.serverTimestamp(),
        'lastUpdated': lastUpdated,
      });

      transaction.update(itemDocRef, {
        'averageRating': newRatingSum / newReviewCount,
        'ratingSum': newRatingSum,
        'reviewCount': newReviewCount,
      });
    });
  }

  Future<void> deleteReview({
    required String reviewDocId,
    required String itemId,
    required int rating,
  }) async {
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemDocRef);

      double newRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0).toDouble() - rating;
      int newReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0) - 1;

      if (newReviewCount > 0) {
        transaction.update(itemDocRef, {
          'averageRating': newRatingSum / newReviewCount,
          'ratingSum': newRatingSum,
          'reviewCount': newReviewCount,
        });
      } else {
        transaction.update(itemDocRef, {
          'averageRating': 0.0,
          'ratingSum': 0,
          'reviewCount': 0,
        });
      }
      transaction.delete(reviewDocRef);
    });
  }

  Stream<QuerySnapshot> getReviews(String itemId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .snapshots();
  }
}