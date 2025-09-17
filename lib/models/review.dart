// lib/models/review.dart - Enhanced version
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String itemId;
  final String userId;
  final String? userName;
  final double rating;
  final String? comment;
  final Timestamp createdAt;
  final Timestamp? lastUpdated;

  Review({
    required this.itemId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.lastUpdated,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      itemId: data['itemId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String?,
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      lastUpdated: data['lastUpdated'] as Timestamp?,
    );
  }

  // Added: toMap method for easier serialization
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }

  // Added: copyWith method for easier updates
  Review copyWith({
    String? itemId,
    String? userId,
    String? userName,
    double? rating,
    String? comment,
    Timestamp? createdAt,
    Timestamp? lastUpdated,
  }) {
    return Review(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Review(itemId: $itemId, userId: $userId, userName: $userName, rating: $rating, comment: $comment)';
  }
}