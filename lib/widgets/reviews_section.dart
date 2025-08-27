// lib/widgets/reviews_section.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/reviews_service.dart';
import 'package:nearnest/models/review.dart';

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
                _showAddReviewDialog(context);
              },
              icon: const Icon(Icons.star_border),
              label: const Text('Add Review'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: ReviewsService().getReviews(itemId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No reviews yet. Be the first to review!'),
                ),
              );
            }

            final reviews = snapshot.data!.docs;
            final userIds = reviews.map((doc) => doc['userId'] as String?).whereType<String>().toList();

            if (userIds.isEmpty) {
                return const Center(child: Text('No user data found.'));
            }

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: userIds).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error fetching user data: ${userSnapshot.error}'));
                }
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                // This is the updated section.
                final userMap = {for (var doc in userSnapshot.data!.docs) doc.id: doc.data() as Map<String, dynamic>};

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final reviewData = reviews[index].data() as Map<String, dynamic>;
                    final review = Review.fromMap(reviewData);

                    // Ensure you cast to the correct type before accessing properties
                    final reviewerName = userMap[review.userId]?['name'] ?? 'Anonymous';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person, size: 40),
                        title: Row(
                          children: [
                            Text(reviewerName),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        subtitle: Text(review.comment ?? 'No comment provided.'),
                        trailing: review.createdAt != null
                            ? Text(
                                '${(review.createdAt as Timestamp).toDate().day}/${(review.createdAt as Timestamp).toDate().month}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            : const Text(
                                'Just now',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    double currentRating = 0.0;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add a Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tap a star to rate:'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              currentRating = index + 1.0;
                            });
                          },
                          icon: Icon(
                            index < currentRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: currentRating > 0
                      ? () async {
                          try {
                            await ReviewsService().addReview(
                              itemId: itemId,
                              rating: currentRating.toInt(),
                              comment: commentController.text,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Review added successfully!')),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add review: $e')),
                            );
                          }
                        }
                      : null,
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}