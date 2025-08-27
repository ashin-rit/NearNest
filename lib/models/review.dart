  // lib/models/review.dart


  class Review {
    final String itemId;
    final String userId;
    final double rating;
    final String? comment;
    final dynamic createdAt;

    Review({
      required this.itemId,
      required this.userId,
      required this.rating,
      this.comment,
      this.createdAt,
    });

    // Factory constructor to create a Review from a Firestore document
    factory Review.fromMap(Map<String, dynamic> data) {
      return Review(
        itemId: data['itemId'] as String,
        userId: data['userId'] as String,
        rating: (data['rating'] as num).toDouble(),
        comment: data['comment'] as String?,
        createdAt: data['createdAt'],
      );
    }
  }