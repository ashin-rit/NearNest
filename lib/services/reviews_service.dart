// lib/services/reviews_service.dart - Enhanced version with response support
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

    final reviewDocId = '${user.uid}_$itemId';
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final String userName = userDoc.data()?['name'] ?? 'Anonymous';

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewDocRef);
      final itemSnapshot = await transaction.get(itemDocRef);

      double newRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0.0).toDouble();
      int newReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0);

      if (reviewSnapshot.exists) {
        final oldRating = (reviewSnapshot.data()?['rating'] ?? 0).toDouble();
        newRatingSum = newRatingSum - oldRating + rating;
      } else {
        newReviewCount++;
        newRatingSum += rating;
      }

      newRatingSum = newRatingSum < 0 ? 0 : newRatingSum;
      newReviewCount = newReviewCount < 0 ? 0 : newReviewCount;

      double newAverageRating = 0.0;
      if (newReviewCount > 0 && newRatingSum > 0) {
        newAverageRating = newRatingSum / newReviewCount;
        newAverageRating = newAverageRating.clamp(0.0, 5.0);
      }

      // Preserve existing response data when updating review
      Map<String, dynamic> reviewData = {
        'itemId': itemId,
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': reviewSnapshot.exists && reviewSnapshot.data()?['createdAt'] != null
            ? reviewSnapshot.data()!['createdAt']
            : FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Preserve existing business response if it exists
      if (reviewSnapshot.exists) {
        final existingData = reviewSnapshot.data()!;
        if (existingData['businessResponse'] != null) {
          reviewData['businessResponse'] = existingData['businessResponse'];
          reviewData['responseDate'] = existingData['responseDate'];
          reviewData['respondedBy'] = existingData['respondedBy'];
        }
      }

      transaction.set(reviewDocRef, reviewData);

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

    final reviewDocId = '${user.uid}_$itemId';
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);
    final itemDocRef = _firestore.collection('users').doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemDocRef);

      double currentRatingSum = (itemSnapshot.data()?['ratingSum'] ?? 0.0).toDouble();
      int currentReviewCount = (itemSnapshot.data()?['reviewCount'] ?? 0);

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

  // NEW: Add business response to a review
  Future<void> addBusinessResponse({
    required String itemId,
    required String customerId,
    required String response,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Verify that the current user is the business owner
    final businessDoc = await _firestore.collection('users').doc(itemId).get();
    if (!businessDoc.exists || businessDoc.id != user.uid) {
      throw Exception('You are not authorized to respond to this review.');
    }

    final businessData = businessDoc.data()!;
    final businessName = businessData['name'] ?? 'Business Owner';

    final reviewDocId = '${customerId}_$itemId';
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);

    await reviewDocRef.update({
      'businessResponse': response,
      'responseDate': FieldValue.serverTimestamp(),
      'respondedBy': businessName,
    });
  }

  // NEW: Update business response
  Future<void> updateBusinessResponse({
    required String itemId,
    required String customerId,
    required String response,
  }) async {
    await addBusinessResponse(
      itemId: itemId,
      customerId: customerId,
      response: response,
    );
  }

  // NEW: Delete business response
  Future<void> deleteBusinessResponse({
    required String itemId,
    required String customerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final reviewDocId = '${customerId}_$itemId';
    final reviewDocRef = _firestore.collection('reviews').doc(reviewDocId);

    await reviewDocRef.update({
      'businessResponse': FieldValue.delete(),
      'responseDate': FieldValue.delete(),
      'respondedBy': FieldValue.delete(),
    });
  }

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

  // NEW: Get reviews for business owner to manage
  Stream<QuerySnapshot> getBusinessReviews(String businessId) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // NEW: Get review statistics for business
  Future<Map<String, dynamic>> getBusinessReviewStats(String businessId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: businessId)
          .get();

      final reviews = reviewsSnapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();
      
      final totalReviews = reviews.length;
      if (totalReviews == 0) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
          'responseRate': 0.0,
          'recentReviews': 0,
        };
      }

      double totalRating = 0;
      int responsedReviews = 0;
      int recentReviews = 0;
      Map<String, int> ratingDistribution = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      for (final review in reviews) {
        totalRating += review.rating;
        
        // Count responses
        if (review.hasResponse) {
          responsedReviews++;
        }
        
        // Count recent reviews
        if (review.createdAt.toDate().isAfter(oneWeekAgo)) {
          recentReviews++;
        }
        
        // Rating distribution
        final rating = review.rating.round().toString();
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

      return {
        'totalReviews': totalReviews,
        'averageRating': totalRating / totalReviews,
        'ratingDistribution': ratingDistribution,
        'responseRate': totalReviews > 0 ? (responsedReviews / totalReviews) * 100 : 0.0,
        'recentReviews': recentReviews,
        'respondedReviews': responsedReviews,
      };
    } catch (e) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'responseRate': 0.0,
        'recentReviews': 0,
        'respondedReviews': 0,
      };
    }
  }
}