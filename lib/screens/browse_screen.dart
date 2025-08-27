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
          throw 'Location permissions are denied. Please grant permissions to see distances.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. We cannot get your location.';
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Calculate distance in kilometers
  double _distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude) / 1000;
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
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (_isLoadingLocation)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_locationError.isNotEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_locationError, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _determinePosition,
                    child: const Text('Refresh Location'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', whereIn: ['Shop', 'Services']).snapshots(),
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

                final List<DocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String name = data['name']?.toLowerCase() ?? '';
                  final String query = _searchQuery.toLowerCase();
                  return name.contains(query);
                }).toList();
                
                if (_currentPosition != null) {
                  filteredDocs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final double latA = (dataA['latitude'] as num?)?.toDouble() ?? 0.0;
                    final double lonA = (dataA['longitude'] as num?)?.toDouble() ?? 0.0;
                    final double latB = (dataB['latitude'] as num?)?.toDouble() ?? 0.0;
                    final double lonB = (dataB['longitude'] as num?)?.toDouble() ?? 0.0;

                    final distanceA = _distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      latA,
                      lonA,
                    );
                    final distanceB = _distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      latB,
                      lonB,
                    );
                    return distanceA.compareTo(distanceB);
                  });
                }

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching results found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String name = data['name'] ?? 'N/A';
                    final String role = data['role'] ?? 'N/A';
                    final String imageUrl = data['imageUrl'] ?? '';
                    final String description = data['description'] ?? 'No description.';
                    final double? lat = (data['latitude'] as num?)?.toDouble();
                    final double? lon = (data['longitude'] as num?)?.toDouble();

                    String distanceText = 'Distance: N/A';
                    if (_currentPosition != null && lat != null && lon != null) {
                      final distance = _distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lon);
                      distanceText = 'Distance: ${distance.toStringAsFixed(2)} km';
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
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