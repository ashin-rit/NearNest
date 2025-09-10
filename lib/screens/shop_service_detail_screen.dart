// lib/screens/shop_service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/products_screen.dart';
import 'package:nearnest/screens/review_screen.dart';
import 'package:nearnest/services/favorites_service.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/screens/common_widgets/date_time_picker.dart';
import 'package:nearnest/models/service_package_model.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:nearnest/widgets/reviews_section.dart';

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
  final BookingService _bookingService = BookingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showBookingDialog(ServicePackage package) async {
    DateTime? selectedDateTime;
    String? taskDescription;
    final _taskDescriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Book ${package.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please select a preferred date and time for your booking.'),
                const SizedBox(height: 20),
                DateTimePicker(
                  onDateTimeChanged: (dateTime) {
                    selectedDateTime = dateTime;
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDateTime != null) {
                  await _bookingService.createBooking(
                    serviceProviderId: widget.itemId,
                    serviceName: package.name,
                    bookingTime: Timestamp.fromDate(selectedDateTime!),
                    taskDescription: _taskDescriptionController.text.isNotEmpty ? _taskDescriptionController.text : null,
                    servicePrice: package.price,
                    serviceDuration: package.durationInMinutes,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking request sent successfully!')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a date and time.')),
                  );
                }
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.data['name'] ?? 'N/A';
    final String description = widget.data['description'] ?? 'No description.';
    final String imageUrl = widget.data['imageUrl'] ?? '';
    final String role = widget.data['role'] ?? 'N/A';
    final String itemId = widget.itemId;

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
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 250),
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
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('users').doc(itemId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
                      final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: averageRating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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
                          if (role == 'Shop') ...[
                            ElevatedButton(
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
                              child: const Text('View Products'),
                            ),
                          ] else if (role == 'Services') ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Available Service Packages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                          .collection('service_packages')
                          .where('serviceProviderId', isEqualTo: itemId)
                          .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text('This service provider has no packages listed yet.'));
                                }
                                final packages = snapshot.data!.docs
                                    .map((doc) => ServicePackage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
                                    .toList();
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: packages.length,
                                  itemBuilder: (context, index) {
                                    final package = packages[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        title: Text(package.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Description: ${package.description}'),
                                            Text('Duration: ${package.durationInMinutes} mins'),
                                            Text('Price: ₹${package.price.toStringAsFixed(2)}'),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () => _showBookingDialog(package),
                                          child: const Text('Book Now'),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 24),
                          ReviewsSection(itemId: itemId, averageRating: averageRating, reviewCount: reviewCount),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}