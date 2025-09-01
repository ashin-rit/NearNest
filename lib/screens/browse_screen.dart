// lib/screens/browse_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/shop_service_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String _locationError = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _isSearching = _searchQuery.isNotEmpty;
      });
    });
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them to see distances.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied. Please grant permission to see distances.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. We cannot request permissions.';
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _buildQuery(String role) {
    Query query = FirebaseFirestore.instance.collection('users');
    query = query.where('role', isEqualTo: role);
    return query.snapshots();
  }

  Widget _buildList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery(role),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No $role found.'));
        }

        final allItems = snapshot.data!.docs.toList();

        final filteredItems = allItems.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          final name = data['name']?.toString().toLowerCase() ?? '';
          final description = data['description']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();

        if (_isSearching && filteredItems.isEmpty) {
          return Center(
              child: Text('No $role found matching your criteria.'));
        }

        if (_currentPosition != null) {
          filteredItems.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final geoPointA = dataA['location'] as GeoPoint?;
            final geoPointB = dataB['location'] as GeoPoint?;

            if (geoPointA == null || geoPointB == null) return 0;

            final distanceA = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              geoPointA.latitude,
              geoPointA.longitude,
            );
            final distanceB = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              geoPointB.latitude,
              geoPointB.longitude,
            );
            return distanceA.compareTo(distanceB);
          });
        }
        
        return ListView.builder(
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final doc = filteredItems[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'N/A';
            final description = data['description'] ?? 'No description.';
            final imageUrl = data['imageUrl'];
            final isDeliveryAvailable = data['isDeliveryAvailable'] ?? false;
            final geoPoint = data['location'] as GeoPoint?;
            final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;

            String distanceText = '';
            if (_currentPosition != null && geoPoint != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                geoPoint.latitude,
                geoPoint.longitude,
              );
              distanceText =
                  '${(distanceInMeters / 1000).toStringAsFixed(2)} km away';
            }

            return Card(
              margin: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopServiceDetailScreen(
                        itemId: doc.id,
                        data: data,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 70))
                            : Icon(
                                role == 'Shop' ? Icons.store : Icons.business_center,
                                size: 70,
                                color: Theme.of(context).primaryColor,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(distanceText, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (rating > 0)
                              RatingBarIndicator(
                                rating: rating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 18.0,
                                direction: Axis.horizontal,
                              ),
                            const SizedBox(height: 8),
                            if (isDeliveryAvailable)
                              Row(
                                children: [
                                  Icon(Icons.delivery_dining, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delivery Available',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for shops or services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Shops'),
              Tab(text: 'Services'),
            ],
          ),
          if (_isLoadingLocation)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_locationError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _locationError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                children: [
                  _buildList('Shop'),
                  _buildList('Services'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}