// lib/screens/shop_service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/products_screen.dart';
import 'package:nearnest/screens/review_screen.dart';
import 'package:nearnest/services/favorites_service.dart';


class ShopServiceDetailScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const ShopServiceDetailScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  @override
  State<ShopServiceDetailScreen> createState() => _ShopServiceDetailScreenState();
}

class _ShopServiceDetailScreenState extends State<ShopServiceDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  @override
  Widget build(BuildContext context) {
    final String name = widget.data['name'] ?? 'N/A';
    final String description = widget.data['description'] ?? 'No description.';
    final String imageUrl = widget.data['imageUrl'] ?? '';
    final String role = widget.data['role'] ?? 'N/A';
    final String itemId = widget.itemId;
    final bool isDeliveryAvailable = widget.data['isDeliveryAvailable'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          StreamBuilder<List<String>>(
            stream: _favoritesService.getFavoriteItemIds(),
            builder: (context, snapshot) {
              final isFavorite = snapshot.hasData && snapshot.data!.contains(itemId);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () async {
                  if (isFavorite) {
                    await _favoritesService.removeFavorite(itemId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name removed from favorites.')),
                    );
                  } else {
                    await _favoritesService.addFavorite(itemId, name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name added to favorites.')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 250),
              ),
            if (imageUrl.isEmpty)
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.grey[300],
                child: Icon(
                  role == 'Shop' ? Icons.store : Icons.business_center,
                  size: 100,
                  color: Colors.grey[600],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isDeliveryAvailable)
                    Row(
                      children: [
                        Icon(Icons.delivery_dining, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Delivery Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (role == 'Shop')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsScreen(
                              shopId: itemId,
                              shopName: name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Browse Products'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildReviewsSection(context, itemId, name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context, String shopId, String shopName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(itemId: shopId),
                  ),
                );
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Write a Review'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reviews').where('itemId', isEqualTo: shopId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No reviews yet. Be the first to review!');
            }

            final reviews = snapshot.data!.docs;
            final double averageRating = reviews.map((doc) => (doc.data() as Map<String, dynamic>)['rating'] as num).reduce((a, b) => a + b) / reviews.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 5),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(' (${reviews.length} reviews)'),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final reviewData = reviews[index].data() as Map<String, dynamic>;
                    final String comment = reviewData['comment'] ?? '';
                    final double rating = (reviewData['rating'] as num).toDouble();
                    final String userId = reviewData['userId'] ?? 'Unknown User';

                    return ListTile(
                      leading: const Icon(Icons.person_pin),
                      title: Text(userId),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          Text(comment),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}