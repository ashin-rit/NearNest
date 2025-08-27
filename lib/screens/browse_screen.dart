// lib/screens/browse_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/shop_service_detail_screen.dart';
import 'package:geolocator/geolocator.dart'; // Import the geolocator package

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
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

      _currentPosition = await Geolocator.getCurrentPosition();
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

  @override
  Widget build(BuildContext context) {
    return Column(
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
        if (_isLoadingLocation)
          const Center(child: CircularProgressIndicator())
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No shops or services found.'));
                }

                // Debugging: Print the total number of documents

                final shops = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  
                  if (data == null) {
                    print('Document ID: ${doc.id} | Data is null, skipping.');
                    return false;
                  }

                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final role = data['role']?.toString().toLowerCase() ?? '';
                  final description = data['description']?.toString().toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();


                  return (name.contains(query) || description.contains(query)) &&
                      (role == 'shop' || role == 'services');
                }).toList();

                if (shops.isEmpty) {
                  return const Center(
                      child: Text('No shops or services found matching your search.'));
                }

                return ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final doc = shops[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'N/A';
                    final description = data['description'] ?? 'No description.';
                    final imageUrl = data['imageUrl'];
                    final role = data['role'] ?? 'N/A';
                    final isDeliveryAvailable = data['isDeliveryAvailable'] ?? false;
                    final geoPoint = data['location'] as GeoPoint?;

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
                      child: ListTile(
                        leading: imageUrl != null && imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image, size: 50)),
                              )
                            : Icon(
                                role == 'Shop' ? Icons.store : Icons.business_center,
                                size: 50,
                                color: Theme.of(context).primaryColor,
                              ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(distanceText, style: TextStyle(color: Colors.grey[600])),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}