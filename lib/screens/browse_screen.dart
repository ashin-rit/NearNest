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

class _BrowseScreenState extends State<BrowseScreen>
    with TickerProviderStateMixin {
  final Map<String, TextEditingController> _searchControllers = {
    'Shop': TextEditingController(),
    'Services': TextEditingController(),
  };
  final AuthService _authService = AuthService();
  final Map<String, String> _searchQueries = {'Shop': '', 'Services': ''};
  GeoPoint? _userLocation;
  bool _isLoading = true;
  final Map<String, String?> _selectedCategories = {
    'Shop': null,
    'Services': null,
  };
  final Map<String, int?> _minRatings = {'Shop': null, 'Services': null};
  final Map<String, double> _maxDistances = {'Shop': 100, 'Services': 100};
  final Map<String, bool> _isDeliveryFilterOn = {
    'Shop': false,
    'Services': false,
  };

  // Dynamic categories loaded from Firestore
  final Map<String, List<String>> _dynamicCategories = {
    'Shop': [],
    'Services': [],
  };
  final Map<String, bool> _categoriesLoaded = {
    'Shop': false,
    'Services': false,
  };

  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // Modern Color Scheme
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

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
          SnackBar(
            content: const Text('Failed to load user data.'),
            backgroundColor: warningOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
    _filterAnimationController.dispose();
    _searchControllers['Shop']!.dispose();
    _searchControllers['Services']!.dispose();
    super.dispose();
  }

  double _getSafeRating(dynamic rating) {
    if (rating == null) return 0.0;

    if (rating is num) {
      final doubleRating = rating.toDouble();
      if (doubleRating.isNaN || doubleRating.isInfinite) return 0.0;
      return doubleRating.clamp(0.0, 5.0);
    }

    return 0.0;
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

  List<QueryDocumentSnapshot> _sortAndFilterResults(
    List<QueryDocumentSnapshot> docs,
    String role,
  ) {
    var filteredDocs = docs;

    if (role == 'Shop' && _isDeliveryFilterOn['Shop']!) {
      filteredDocs = filteredDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['isDeliveryAvailable'] as bool?) ?? false;
      }).toList();
    }

    final filteredByRating = filteredDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      final minRating = _minRatings[role] ?? 0;
      return rating >= minRating;
    }).toList();

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading ${role.toLowerCase()}s...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  role == 'Shop'
                      ? Icons.store_outlined
                      : Icons.business_center_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${role.toLowerCase()}s found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search terms',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No matches found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try different search terms or clear filters',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final sortedDocs = _sortAndFilterResults(filteredItems, role);

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: sortedDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'N/A';
            final category = data['category'] ?? 'No Category';
            final imageUrl = data['imageUrl'];
            final isDeliveryAvailable = data['isDeliveryAvailable'] ?? false;
            final geoPoint = data['location'] as GeoPoint?;
            final averageRating =
                (data['averageRating'] as num?)?.toDouble() ?? 0.0;
            final safeRating = averageRating.isFinite ? averageRating : 0.0;

            String distanceText = '';
            if (_userLocation != null && geoPoint != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                geoPoint.latitude,
                geoPoint.longitude,
              );
              distanceText =
                  '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
            }

            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutQuart,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                color: cardColor,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ShopServiceDetailScreen(itemId: doc.id, data: data),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Container with modern styling
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [lightBlue, accentBlue.withOpacity(0.3)],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    lightBlue,
                                                    accentBlue.withOpacity(0.3),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                size: 32,
                                                color: primaryBlue,
                                              ),
                                            ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          lightBlue,
                                          accentBlue.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      role == 'Shop'
                                          ? Icons.store_outlined
                                          : Icons.business_center_outlined,
                                      size: 32,
                                      color: primaryBlue,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and Category
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: lightBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category,
                                  style: TextStyle(
                                    color: darkBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Distance and Delivery Row
                              Row(
                                children: [
                                  if (_userLocation != null &&
                                      geoPoint != null) ...[
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distanceText,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (isDeliveryAvailable &&
                                      _userLocation != null &&
                                      geoPoint != null)
                                    const SizedBox(width: 16),
                                  if (isDeliveryAvailable)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: successGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_shipping_outlined,
                                            color: successGreen,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Delivery',
                                            style: TextStyle(
                                              color: successGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Rating
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: safeRating,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 16.0,
                                    direction: Axis.horizontal,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    averageRating == 0.0
                                        ? 'No ratings'
                                        : safeRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: averageRating > 0
                                          ? Colors.grey[700]
                                          : Colors.grey[500],
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
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoryDialog(String currentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final categories = _dynamicCategories[currentRole] ?? [];
            final selectedCategory = _selectedCategories[currentRole];

            return Container(
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_categoriesLoaded[currentRole]!)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (categories.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No categories available'),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: [
                        // All categories chip
                        _buildModernChip(
                          label: 'All Categories',
                          isSelected: selectedCategory == null,
                          onTap: () {
                            modalSetState(() {
                              _selectedCategories[currentRole] = null;
                            });
                            Navigator.pop(context);
                            setState(() {});
                          },
                        ),
                        // Individual category chips
                        ...categories
                            .map(
                              (category) => _buildModernChip(
                                label: category,
                                isSelected: selectedCategory == category,
                                onTap: () {
                                  modalSetState(() {
                                    _selectedCategories[currentRole] = category;
                                  });
                                  Navigator.pop(context);
                                  setState(() {});
                                },
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : surfaceColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingOption({
    required String title,
    required int? rating,
    required int? currentRating,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRating == rating;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? lightBlue : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryBlue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? darkBlue : Colors.grey[700],
                ),
              ),
            ),
            if (rating != null)
              RatingBarIndicator(
                rating: rating.toDouble(),
                itemBuilder: (context, index) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                itemCount: 5,
                itemSize: 18.0,
                direction: Axis.horizontal,
              ),
          ],
        ),
      ),
    );
  }

  void _showDeliveryDialog(String currentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Delivery Options',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Show only shops with delivery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Filter results to include delivery options',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDeliveryFilterOn[currentRole]!,
                          onChanged: (bool newValue) {
                            modalSetState(() {
                              _isDeliveryFilterOn[currentRole] = newValue;
                            });
                          },
                          activeColor: primaryBlue,
                          activeTrackColor: primaryBlue.withOpacity(0.3),
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDistanceDialog(String currentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Maximum Distance',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_maxDistances[currentRole]!.round()} km',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: darkBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: primaryBlue,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: primaryBlue,
                      overlayColor: primaryBlue.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _maxDistances[currentRole]!,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (double newValue) {
                        modalSetState(() {
                          _maxDistances[currentRole] = newValue;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 km',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '100 km',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRatingDialog(String currentRole) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            final minRating = _minRatings[currentRole];
            return Container(
              decoration: const BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.star_outline, color: primaryBlue, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildRatingOption(
                    title: 'All Ratings',
                    rating: null,
                    currentRating: minRating,
                    onTap: () {
                      modalSetState(() {
                        _minRatings[currentRole] = null;
                      });
                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                  for (int i = 4; i >= 1; i--)
                    _buildRatingOption(
                      title: '$i Stars & Up',
                      rating: i,
                      currentRating: minRating,
                      onTap: () {
                        modalSetState(() {
                          _minRatings[currentRole] = i;
                        });
                        Navigator.pop(context);
                        setState(() {});
                      },
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? primaryBlue : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : primaryBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingFilterChip({
    required String role,
    required VoidCallback onTap,
  }) {
    final minRating = _minRatings[role];
    final isActive = minRating != null;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isActive ? primaryBlue : surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? primaryBlue : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_outline,
                size: 16,
                color: isActive ? Colors.white : primaryBlue,
              ),
              const SizedBox(width: 6),
              if (minRating == null)
                Expanded(
                  child: Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : primaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    '$minRating+ Stars',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : primaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue,
              accentBlue,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Browse Nearby',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue,
                  accentBlue,
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.explore_rounded,
                color: Colors.white24,
                size: 80,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Modern Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primaryBlue,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Shops'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_center_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Services'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading your location...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_userLocation == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Location Not Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please update your location in your profile to see nearby shops and services',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverFillRemaining(
                child: TabBarView(
                  children: [
                    _buildTabContent('Shop', 'Search for shops...'),
                    _buildTabContent('Services', 'Search for services...'),
                  ],
                ),
              ),
          ],
        ),
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
        // Modern Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchControllers[role],
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[500],
                  size: 24,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),

        // Modern Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              if (role == 'Shop') ...[
                _buildFilterChip(
                  title: 'Delivery',
                  value: deliveryText,
                  icon: Icons.local_shipping_outlined,
                  onTap: () => _showDeliveryDialog(role),
                  isActive: _isDeliveryFilterOn[role]!,
                ),
                const SizedBox(width: 8),
              ],
              _buildFilterChip(
                title: 'Category',
                value: selectedCategory,
                icon: Icons.category_outlined,
                onTap: () => _showCategoryDialog(role),
                isActive: _selectedCategories[role] != null,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                title: 'Distance',
                value: distanceText,
                icon: Icons.location_on_outlined,
                onTap: () => _showDistanceDialog(role),
                isActive: maxDistance < 100,
              ),
              const SizedBox(width: 8),
              _buildRatingFilterChip(
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