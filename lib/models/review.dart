// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String itemId;
  final String userId;
  final double rating;
  final String? comment;
  final Timestamp createdAt;
  final Timestamp? lastUpdated;

  Review({
    required this.itemId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.lastUpdated,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      itemId: data['itemId'] as String,
      userId: data['userId'] as String,
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }
}