// lib/models/review.dart - Enhanced version with response support
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String itemId;
  final String userId;
  final String? userName;
  final double rating;
  final String? comment;
  final Timestamp createdAt;
  final Timestamp? lastUpdated;
  
  // New fields for business response
  final String? businessResponse;
  final Timestamp? responseDate;
  final String? respondedBy; // Business owner/manager name

  Review({
    required this.itemId,
    required this.userId,
    this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.lastUpdated,
    this.businessResponse,
    this.responseDate,
    this.respondedBy,
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
      businessResponse: data['businessResponse'] as String?,
      responseDate: data['responseDate'] as Timestamp?,
      respondedBy: data['respondedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'businessResponse': businessResponse,
      'responseDate': responseDate,
      'respondedBy': respondedBy,
    };
  }

  Review copyWith({
    String? itemId,
    String? userId,
    String? userName,
    double? rating,
    String? comment,
    Timestamp? createdAt,
    Timestamp? lastUpdated,
    String? businessResponse,
    Timestamp? responseDate,
    String? respondedBy,
  }) {
    return Review(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      businessResponse: businessResponse ?? this.businessResponse,
      responseDate: responseDate ?? this.responseDate,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }

  // Helper methods
  bool get hasResponse => businessResponse != null && businessResponse!.isNotEmpty;

  @override
  String toString() {
    return 'Review(itemId: $itemId, userId: $userId, userName: $userName, rating: $rating, comment: $comment, hasResponse: $hasResponse)';
  }
}