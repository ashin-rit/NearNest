// lib/widgets/reviews_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/reviews_service.dart';
import 'package:nearnest/models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:nearnest/screens/review_screen.dart';

class ReviewsSection extends StatelessWidget {
  final String itemId;
  final double averageRating;
  final int reviewCount;

  const ReviewsSection({
    super.key,
    required this.itemId,
    required this.averageRating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ReviewsService _reviewsService = ReviewsService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ratings & Reviews',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 30),
            const SizedBox(width: 8),
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($reviewCount reviews)',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(itemId: itemId),
                  ),
                );
              },
              icon: const Icon(Icons.star_border),
              label: const Text('Add Review'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _reviewsService.getReviews(itemId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No reviews yet. Be the first!'));
            }

            final reviews = snapshot.data!.docs;

            return Column(
              children: reviews.map((doc) {
                final reviewData = doc.data() as Map<String, dynamic>;
                final review = Review.fromMap(reviewData);

                final isUserReview = currentUser != null && review.userId == currentUser.uid;
                String? displayDate;
                if (review.lastUpdated != null) {
                  displayDate = DateFormat('MMM d, yyyy').format(review.lastUpdated!.toDate());
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(review.userId),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: review.rating,
                              itemBuilder: (context, index) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                              direction: Axis.horizontal,
                            ),
                            if (displayDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  'Edited on $displayDate',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ),
                        Text(review.comment ?? 'No comment provided.'),
                      ],
                    ),
                    trailing: isUserReview
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReviewScreen(
                                        itemId: itemId,
                                        initialReview: review,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _reviewsService.deleteReview(
                                    reviewDocId: doc.id,
                                    itemId: itemId,
                                    rating: review.rating.toInt(),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Review deleted successfully!')),
                                  );
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}