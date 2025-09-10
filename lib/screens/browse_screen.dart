// lib/screens/browse_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/shop_service_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/services/auth_service.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final Map<String, TextEditingController> _searchControllers = {
    'Shop': TextEditingController(),
    'Services': TextEditingController(),
  };
  final AuthService _authService = AuthService();
  final Map<String, String> _searchQueries = {'Shop': '', 'Services': ''};
  GeoPoint? _userLocation;
  bool _isLoading = true;
  final Map<String, String?> _selectedCategories = {'Shop': null, 'Services': null};
  final Map<String, int?> _minRatings = {'Shop': null, 'Services': null};
  final Map<String, double> _maxDistances = {'Shop': 100, 'Services': 100};
  final Map<String, bool> _isDeliveryFilterOn = {'Shop': false, 'Services': false};
  
  // Dynamic categories loaded from Firestore
  final Map<String, List<String>> _dynamicCategories = {'Shop': [], 'Services': []};
  final Map<String, bool> _categoriesLoaded = {'Shop': false, 'Services': false};

  @override
  void initState() {
    super.initState();
    _searchControllers['Shop']!.addListener(() {
      setState(() {
        _searchQueries['Shop'] = _searchControllers['Shop']!.text;
      });
    });
    _searchControllers['Services']!.addListener(() {
      setState(() {
        _searchQueries['Services'] = _searchControllers['Services']!.text;
      });
    });
    _fetchUserData();
    _loadCategories('Shop');
    _loadCategories('Services');
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userData = await _authService.getUserDataByUid(user.uid);
        final data = userData?.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('location')) {
          setState(() {
            _userLocation = data['location'];
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories(String role) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      final Set<String> uniqueCategories = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          uniqueCategories.add(category);
        }
      }
      
      setState(() {
        _dynamicCategories[role] = uniqueCategories.toList()..sort();
        _categoriesLoaded[role] = true;
      });
    } catch (e) {
      print('Error loading categories for $role: $e');
      // Fallback to hardcoded categories if there's an error
      setState(() {
        _dynamicCategories[role] = role == 'Shop'
            ? ['Groceries', 'Electronics', 'Food', 'Retail']
            : ['Plumbing', 'Haircut', 'Consulting', 'Repair'];
        _categoriesLoaded[role] = true;
      });
    }
  }

  @override
  void dispose() {
    _searchControllers['Shop']!.dispose();
    _searchControllers['Services']!.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _buildQuery(String role) {
    Query query = FirebaseFirestore.instance.collection('users');
    query = query.where('role', isEqualTo: role);
    final selectedCategory = _selectedCategories[role];
    if (selectedCategory != null && selectedCategory.isNotEmpty) {
      query = query.where('category', isEqualTo: selectedCategory);
    }
    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _sortAndFilterResults(List<QueryDocumentSnapshot> docs, String role) {
    var filteredDocs = docs;

    // Filter by delivery for Shops
    if (role == 'Shop' && _isDeliveryFilterOn['Shop']!) {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['isDeliveryAvailable'] as bool?) ?? false;
      }).toList();
    }

    // Filter by rating
    final filteredByRating = filteredDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      final minRating = _minRatings[role] ?? 0;
      return rating >= minRating;
    }).toList();

    // Filter by distance
    final filteredByDistance = filteredByRating.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final geoPoint = data['location'] as GeoPoint?;
      final maxDistance = _maxDistances[role] ?? 100.0;
      if (_userLocation == null || geoPoint == null) return true;
      final distanceInMeters = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        geoPoint.latitude,
        geoPoint.longitude,
      );
      final distanceInKm = distanceInMeters / 1000;
      return distanceInKm <= maxDistance;
    }).toList();
    
    // Sort by distance as default
    if (_userLocation != null) {
      filteredByDistance.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        final geoPointA = dataA['location'] as GeoPoint?;
        final geoPointB = dataB['location'] as GeoPoint?;
        if (geoPointA == null || geoPointB == null) return 0;
        final distanceA = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          geoPointA.latitude,
          geoPointA.longitude,
        );
        final distanceB = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          geoPointB.latitude,
          geoPointB.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
    }

    return filteredByDistance;
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
          final category = data['category']?.toString().toLowerCase() ?? '';
          final query = _searchQueries[role]!.toLowerCase();
          return name.contains(query) || category.contains(query);
        }).toList();

        if (filteredItems.isEmpty && _searchQueries[role]!.isNotEmpty) {
          return Center(child: Text('No $role found matching your criteria.'));
        }

        final sortedDocs = _sortAndFilterResults(filteredItems, role);

        return ListView.builder(
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'N/A';
            final category = data['category'] ?? 'No Category.';
            final imageUrl = data['imageUrl'];
            final isDeliveryAvailable = data['isDeliveryAvailable'] ?? false;
            final geoPoint = data['location'] as GeoPoint?;
            final averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;

            String distanceText = '';
            if (_userLocation != null && geoPoint != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                geoPoint.latitude,
                geoPoint.longitude,
              );
              distanceText =
                  '${(distanceInMeters / 1000).toStringAsFixed(2)} km away';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 70))
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            if (_userLocation != null && geoPoint != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(distanceText, style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            const SizedBox(height: 4),
                            if (isDeliveryAvailable)
                              Row(
                                children: [
                                  Icon(Icons.delivery_dining, color: Colors.green[700], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Delivery Available',
                                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            // Display the average rating at the bottom
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: averageRating,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemCount: 5,
                                  itemSize: 18.0,
                                  direction: Axis.horizontal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
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

  void _showCategoryDialog(String currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            // Use dynamic categories if loaded, otherwise show loading or empty state
            final categories = _dynamicCategories[currentRole] ?? [];
            final selectedCategory = _selectedCategories[currentRole];

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (!_categoriesLoaded[currentRole]!)
                      const Center(child: CircularProgressIndicator())
                    else if (categories.isEmpty)
                      const Center(child: Text('No categories available'))
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: selectedCategory == null,
                            onSelected: (bool selected) {
                              modalSetState(() {
                                _selectedCategories[currentRole] = null;
                                Navigator.pop(context);
                                setState(() {});
                              });
                            },
                          ),
                          ...categories.map((category) => FilterChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (bool selected) {
                              modalSetState(() {
                                _selectedCategories[currentRole] = selected ? category : null;
                                Navigator.pop(context);
                                setState(() {});
                              });
                            },
                          )).toList(),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDistanceDialog(String currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Max Distance',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0 km', style: TextStyle(color: Colors.grey[700])),
                        Text(
                          '${_maxDistances[currentRole]!.round()} km',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text('100 km', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                    Slider(
                      value: _maxDistances[currentRole]!,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${_maxDistances[currentRole]!.round()} km',
                      onChanged: (double newValue) {
                        modalSetState(() {
                          _maxDistances[currentRole] = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(String currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final minRating = _minRatings[currentRole];
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Rating',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    RadioListTile<int?>(
                      title: const Text('All Ratings'),
                      value: null,
                      groupValue: minRating,
                      onChanged: (int? value) {
                        modalSetState(() {
                          _minRatings[currentRole] = value;
                          Navigator.pop(context);
                          setState(() {});
                        });
                      },
                    ),
                    for (int i = 4; i >= 1; i--)
                      RadioListTile<int>(
                        title: IntrinsicWidth(
                          child: Row(
                            children: [
                              Expanded(child: Text('$i Stars & Up')),
                              const SizedBox(width: 8),
                              RatingBarIndicator(
                                rating: i.toDouble(),
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 18.0,
                                direction: Axis.horizontal,
                              ),
                            ],
                          ),
                        ),
                        value: i,
                        groupValue: minRating,
                        onChanged: (int? value) {
                          modalSetState(() {
                            _minRatings[currentRole] = value;
                            Navigator.pop(context);
                            setState(() {});
                          });
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeliveryDialog(String currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Availability',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Show shops with delivery available'),
                      value: _isDeliveryFilterOn[currentRole]!,
                      onChanged: (bool newValue) {
                        modalSetState(() {
                          _isDeliveryFilterOn[currentRole] = newValue;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingFilterTile({
    required String role,
    required VoidCallback onTap,
  }) {
    final minRating = _minRatings[role];
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              if (minRating == null)
                const Expanded(
                  child: Text(
                    'Rating',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      RatingBarIndicator(
                        rating: minRating.toDouble(),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 14.0,
                        direction: Axis.horizontal,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Shops'),
                  Tab(text: 'Services'),
                ],
              ),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_userLocation == null)
                const Expanded(child: Center(child: Text('User location not available. Please update your profile.')))
              else
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTabContent('Shop', 'Search for shops...'),
                      _buildTabContent('Services', 'Search for services...'),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String role, String hintText) {
    final selectedCategory = _selectedCategories[role] ?? 'Category';
    final maxDistance = _maxDistances[role]!;
    final distanceText = '${maxDistance.round()} km';
    final deliveryText = _isDeliveryFilterOn[role]! ? 'Available' : 'Delivery';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchControllers[role],
            decoration: InputDecoration(
              hintText: hintText,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (role == 'Shop') ...[
                _buildFilterTile(
                  title: 'Delivery',
                  value: deliveryText,
                  icon: Icons.delivery_dining,
                  onTap: () => _showDeliveryDialog(role),
                ),
                const SizedBox(width: 8),
              ],
              _buildFilterTile(
                title: 'Category',
                value: selectedCategory,
                icon: Icons.filter_list,
                onTap: () => _showCategoryDialog(role),
              ),
              const SizedBox(width: 8),
              _buildFilterTile(
                title: 'Distance',
                value: distanceText,
                icon: Icons.location_on,
                onTap: () => _showDistanceDialog(role),
              ),
              const SizedBox(width: 8),
              _buildRatingFilterTile(
                role: role,
                onTap: () => _showRatingDialog(role),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList(role)),
      ],
    );
  }
}