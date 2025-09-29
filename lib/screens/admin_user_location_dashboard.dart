// lib/screens/admin_user_location_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserLocationDashboard extends StatefulWidget {
  const AdminUserLocationDashboard({Key? key}) : super(key: key);

  @override
  State<AdminUserLocationDashboard> createState() => _AdminUserLocationDashboardState();
}

class _AdminUserLocationDashboardState extends State<AdminUserLocationDashboard>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Marker> _markers = [];
  List<DocumentSnapshot> _users = [];
  Map<String, int> _locationStats = {};
  bool _isLoading = true;
  bool _showList = false;
  
  // Multi-level navigation state
  int _currentLevel = 0; // 0: States, 1: Cities, 2: Areas, 3: Users
  List<String> _navigationPath = [];
  String _currentState = '';
  String _currentCity = '';
  String _currentArea = '';
  
  // Data for current level
  Map<String, dynamic> _currentLevelData = {};
  List<DocumentSnapshot> _currentUsers = [];
  
  // Global search functionality
  String _searchQuery = '';
  bool _isSearching = false;
  List<dynamic> _globalSearchResults = [];
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Default map location (India center)
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isNotEqualTo: 'Admin') // Exclude admins
          .get();
      
      setState(() {
        _users = querySnapshot.docs;
        _isLoading = false;
      });
      
      _createMarkers();
      _calculateLocationStats();
      _loadStatesData();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading user data: ${e.toString()}');
    }
  }

  // Global search implementation
  void _performGlobalSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _globalSearchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    List<dynamic> results = [];
    String lowerQuery = query.toLowerCase();

    // Search through all states
    Map<String, int> stateUserCounts = {};
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final state = userData['state']?.toString() ?? 'Unknown';
      stateUserCounts[state] = (stateUserCounts[state] ?? 0) + 1;
    }
    
    for (final state in stateUserCounts.keys) {
      if (state.toLowerCase().contains(lowerQuery)) {
        results.add({
          'type': 'state',
          'name': state,
          'userCount': stateUserCounts[state],
          'icon': Icons.map,
          'color': Colors.purple,
        });
      }
    }

    // Search through all cities
    Map<String, Map<String, dynamic>> cityData = {};
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final state = userData['state']?.toString() ?? 'Unknown';
      final city = userData['city']?.toString() ?? 'Unknown';
      final key = '$city|$state';
      
      if (!cityData.containsKey(key)) {
        cityData[key] = {'state': state, 'city': city, 'userCount': 0};
      }
      cityData[key]!['userCount'] = (cityData[key]!['userCount'] ?? 0) + 1;
    }
    
    for (final entry in cityData.entries) {
      final city = entry.value['city'].toString();
      if (city.toLowerCase().contains(lowerQuery)) {
        results.add({
          'type': 'city',
          'name': city,
          'state': entry.value['state'],
          'userCount': entry.value['userCount'],
          'icon': Icons.location_city,
          'color': Colors.blue,
        });
      }
    }

    // Search through all areas
    Map<String, Map<String, dynamic>> areaData = {};
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final state = userData['state']?.toString() ?? 'Unknown';
      final city = userData['city']?.toString() ?? 'Unknown';
      String area = userData['pincode']?.toString() ?? 'Unknown';
      if (area == 'Unknown' && userData['streetAddress'] != null) {
        final street = userData['streetAddress'].toString();
        if (street.isNotEmpty) {
          area = street.split(',').first.trim();
        }
      }
      final key = '$area|$city|$state';
      
      if (!areaData.containsKey(key)) {
        areaData[key] = {'area': area, 'city': city, 'state': state, 'userCount': 0};
      }
      areaData[key]!['userCount'] = (areaData[key]!['userCount'] ?? 0) + 1;
    }
    
    for (final entry in areaData.entries) {
      final area = entry.value['area'].toString();
      if (area.toLowerCase().contains(lowerQuery)) {
        results.add({
          'type': 'area',
          'name': area,
          'city': entry.value['city'],
          'state': entry.value['state'],
          'userCount': entry.value['userCount'],
          'icon': Icons.place,
          'color': Colors.green,
        });
      }
    }

    // Search through users
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final name = userData['name']?.toString().toLowerCase() ?? '';
      final phone = userData['phone']?.toString().toLowerCase() ?? '';
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final address = userData['streetAddress']?.toString().toLowerCase() ?? '';
      
      if (name.contains(lowerQuery) ||
          phone.contains(lowerQuery) ||
          email.contains(lowerQuery) ||
          address.contains(lowerQuery)) {
        results.add({
          'type': 'user',
          'user': user,
          'userData': userData,
          'icon': _getRoleIcon(userData['role'] ?? 'customer'),
          'color': _getRoleColor(userData['role'] ?? 'customer'),
        });
      }
    }

    // Sort results: locations by user count (desc), users alphabetically
    results.sort((a, b) {
      if (a['type'] == 'user' && b['type'] == 'user') {
        return (a['userData']['name'] ?? '').toString().compareTo((b['userData']['name'] ?? '').toString());
      } else if (a['type'] == 'user') {
        return 1;
      } else if (b['type'] == 'user') {
        return -1;
      } else {
        return (b['userCount'] ?? 0).compareTo(a['userCount'] ?? 0);
      }
    });

    setState(() {
      _globalSearchResults = results;
    });
  }

  void _navigateFromSearch(dynamic result) {
    final type = result['type'];
    
    switch (type) {
      case 'state':
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _isSearching = false;
          _showList = true;
        });
        _navigateToLevel(1, result['name']);
        break;
      case 'city':
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _isSearching = false;
          _showList = true;
        });
        _navigateToLevel(1, result['state']);
        Future.delayed(const Duration(milliseconds: 100), () {
          _navigateToLevel(2, result['name']);
        });
        break;
      case 'area':
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _isSearching = false;
          _showList = true;
        });
        _navigateToLevel(1, result['state']);
        Future.delayed(const Duration(milliseconds: 100), () {
          _navigateToLevel(2, result['city']);
          Future.delayed(const Duration(milliseconds: 100), () {
            _navigateToLevel(3, result['name']);
          });
        });
        break;
      case 'user':
        _showUserDetails(result['user']);
        break;
    }
  }

  void _loadStatesData() {
    Map<String, Map<String, dynamic>> stateData = {};
    
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final String state = userData['state'] ?? 'Unknown';
      final String role = userData['role'] ?? 'customer';
      
      if (!stateData.containsKey(state)) {
        stateData[state] = {
          'totalUsers': 0,
          'customers': 0,
          'services': 0,
          'shops': 0,
          'cities': <String>{},
        };
      }
      
      stateData[state]!['totalUsers'] = (stateData[state]!['totalUsers'] ?? 0) + 1;
      
      final roleKey = role.toLowerCase();
      stateData[state]![roleKey] = (stateData[state]![roleKey] ?? 0) + 1;
      
      final citySet = stateData[state]!['cities'] as Set<String>;
      citySet.add(userData['city'] ?? 'Unknown');
    }
    
    // Convert cities Set to count
    for (final state in stateData.keys) {
      final citiesSet = stateData[state]!['cities'] as Set<String>;
      stateData[state]!['citiesCount'] = citiesSet.length;
      stateData[state]!.remove('cities');
    }
    
    setState(() {
      _currentLevelData = stateData;
    });
  }

  void _loadCitiesData(String state) {
    Map<String, Map<String, dynamic>> cityData = {};
    
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final String userState = userData['state'] ?? 'Unknown';
      final String city = userData['city'] ?? 'Unknown';
      final String role = userData['role'] ?? 'customer';
      
      if (userState == state) {
        if (!cityData.containsKey(city)) {
          cityData[city] = {
            'totalUsers': 0,
            'customers': 0,
            'services': 0,
            'shops': 0,
            'areas': <String>{},
          };
        }
        
        cityData[city]!['totalUsers'] = (cityData[city]!['totalUsers'] ?? 0) + 1;
        
        final roleKey = role.toLowerCase();
        cityData[city]![roleKey] = (cityData[city]![roleKey] ?? 0) + 1;
        
        // Create area from pincode or street address
        String area = userData['pincode']?.toString() ?? 'Unknown';
        if (area == 'Unknown' && userData['streetAddress'] != null) {
          final street = userData['streetAddress'].toString();
          if (street.isNotEmpty) {
            area = street.split(',').first.trim();
          }
        }
        final areasSet = cityData[city]!['areas'] as Set<String>;
        areasSet.add(area);
      }
    }
    
    // Convert areas Set to count
    for (final city in cityData.keys) {
      final areasSet = cityData[city]!['areas'] as Set<String>;
      cityData[city]!['areasCount'] = areasSet.length;
      cityData[city]!.remove('areas');
    }
    
    setState(() {
      _currentLevelData = cityData;
    });
  }

  void _loadAreasData(String state, String city) {
    Map<String, Map<String, dynamic>> areaData = {};
    
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final String userState = userData['state'] ?? 'Unknown';
      final String userCity = userData['city'] ?? 'Unknown';
      final String role = userData['role'] ?? 'customer';
      
      if (userState == state && userCity == city) {
        String area = userData['pincode']?.toString() ?? 'Unknown';
        if (area == 'Unknown' && userData['streetAddress'] != null) {
          final street = userData['streetAddress'].toString();
          if (street.isNotEmpty) {
            area = street.split(',').first.trim();
          }
        }
        
        if (!areaData.containsKey(area)) {
          areaData[area] = {
            'totalUsers': 0,
            'customers': 0,
            'services': 0,
            'shops': 0,
          };
        }
        
        areaData[area]!['totalUsers'] = (areaData[area]!['totalUsers'] ?? 0) + 1;
        
        final roleKey = role.toLowerCase();
        areaData[area]![roleKey] = (areaData[area]![roleKey] ?? 0) + 1;
      }
    }
    
    setState(() {
      _currentLevelData = areaData;
    });
  }

  void _loadUsersData(String state, String city, String area) {
    List<DocumentSnapshot> users = [];
    
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final String userState = userData['state'] ?? 'Unknown';
      final String userCity = userData['city'] ?? 'Unknown';
      
      String userArea = userData['pincode']?.toString() ?? 'Unknown';
      if (userArea == 'Unknown' && userData['streetAddress'] != null) {
        final street = userData['streetAddress'].toString();
        if (street.isNotEmpty) {
          userArea = street.split(',').first.trim();
        }
      }
      
      if (userState == state && userCity == city && userArea == area) {
        users.add(user);
      }
    }
    
    setState(() {
      _currentUsers = users;
    });
  }

  void _navigateToLevel(int level, String? item) {
    setState(() {
      _currentLevel = level;
      _searchQuery = '';
      _searchController.clear();
      _isSearching = false;
      
      if (level == 0) {
        // States level
        _navigationPath.clear();
        _currentState = '';
        _currentCity = '';
        _currentArea = '';
        _loadStatesData();
      } else if (level == 1) {
        // Cities level
        _currentState = item!;
        _navigationPath = [item];
        _currentCity = '';
        _currentArea = '';
        _loadCitiesData(item);
      } else if (level == 2) {
        // Areas level
        _currentCity = item!;
        _navigationPath.add(item);
        _currentArea = '';
        _loadAreasData(_currentState, item);
      } else if (level == 3) {
        // Users level
        _currentArea = item!;
        _navigationPath.add(item);
        _loadUsersData(_currentState, _currentCity, item);
      }
    });
  }

  void _goBack() {
    if (_currentLevel > 0) {
      _navigationPath.removeLast();
      _navigateToLevel(_currentLevel - 1, _navigationPath.isEmpty ? null : _navigationPath.last);
    }
  }

  List<dynamic> _getFilteredData() {
    if (_searchQuery.isEmpty) {
      return _currentLevel == 3 ? _currentUsers : _currentLevelData.entries.toList();
    }
    
    if (_currentLevel == 3) {
      return _currentUsers.where((user) {
        final userData = user.data() as Map<String, dynamic>;
        final name = userData['name']?.toString().toLowerCase() ?? '';
        final phone = userData['phone']?.toString().toLowerCase() ?? '';
        final email = userData['email']?.toString().toLowerCase() ?? '';
        final address = userData['streetAddress']?.toString().toLowerCase() ?? '';
        
        return name.contains(_searchQuery.toLowerCase()) ||
               phone.contains(_searchQuery.toLowerCase()) ||
               email.contains(_searchQuery.toLowerCase()) ||
               address.contains(_searchQuery.toLowerCase());
      }).toList();
    } else {
      return _currentLevelData.entries.where((entry) {
        return entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  String _getCurrentLevelTitle() {
    switch (_currentLevel) {
      case 0:
        return 'Browse by State';
      case 1:
        return 'Cities in $_currentState';
      case 2:
        return 'Areas in $_currentCity';
      case 3:
        return 'Users in $_currentArea';
      default:
        return 'Browse Locations';
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return const Color(0xFF10B981); // Green
      case 'services':
        return const Color(0xFF3B82F6); // Blue
      case 'shop':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return Icons.person;
      case 'services':
        return Icons.build;
      case 'shop':
        return Icons.store;
      default:
        return Icons.help_outline;
    }
  }

  void _createMarkers() {
    List<Marker> markers = [];
    
    for (int i = 0; i < _users.length; i++) {
      final userData = _users[i].data() as Map<String, dynamic>;
      final GeoPoint? location = userData['location'] as GeoPoint?;
      final String name = userData['name'] ?? 'Unknown User';
      final String role = userData['role'] ?? 'customer';
      final String city = userData['city'] ?? 'Unknown';
      final String state = userData['state'] ?? 'Unknown';
      
      if (location != null) {
        markers.add(
          Marker(
            point: LatLng(location.latitude, location.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showUserDetails(_users[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: _getRoleColor(role),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getRoleIcon(role),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
    
    // Fit all markers on screen after a short delay
    if (markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), _fitMarkersOnScreen);
    }
  }

  void _calculateLocationStats() {
    Map<String, int> cityStats = {};
    Map<String, int> stateStats = {};
    
    for (final user in _users) {
      final userData = user.data() as Map<String, dynamic>;
      final String city = userData['city'] ?? 'Unknown';
      final String state = userData['state'] ?? 'Unknown';
      
      cityStats[city] = (cityStats[city] ?? 0) + 1;
      stateStats[state] = (stateStats[state] ?? 0) + 1;
    }
    
    setState(() {
      _locationStats = {
        ...cityStats.map((key, value) => MapEntry('$key (City)', value)),
        ...stateStats.map((key, value) => MapEntry('$key (State)', value)),
      };
    });
  }

  void _showUserDetails(DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserDetailsSheet(userData),
    );
  }

  Widget _buildUserDetailsSheet(Map<String, dynamic> userData) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _getRoleColor(userData['role'] ?? 'customer'),
                        child: Text(
                          (userData['name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(userData['role'] ?? 'customer').withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                userData['role'] ?? 'User',
                                style: TextStyle(
                                  color: _getRoleColor(userData['role'] ?? 'customer'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Email', userData['email'] ?? 'N/A', Icons.email),
                  _buildDetailRow('Phone', userData['phone'] ?? 'N/A', Icons.phone),
                  _buildDetailRow('Address', 
                    '${userData['streetAddress'] ?? ''}\n${userData['city'] ?? ''}, ${userData['state'] ?? ''} ${userData['pincode'] ?? ''}',
                    Icons.location_on
                  ),
                  const SizedBox(height: 20),
                  if (userData['location'] != null) ...[
                    const Text(
                      'Coordinates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        'Lat: ${(userData['location'] as GeoPoint).latitude.toStringAsFixed(6)}\n'
                        'Lng: ${(userData['location'] as GeoPoint).longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 105, 105, 105).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading 
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildToggleButtons(),
                  _buildSearchBar(),
                  Expanded(
                    child: _isSearching && _searchQuery.isNotEmpty 
                        ? _buildGlobalSearchResults()
                        : (_showList ? _buildListView() : _buildMapView()),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF3B82F6)),
          SizedBox(height: 16),
          Text(
            'Loading user locations...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color.fromARGB(255, 4, 98, 249)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (_showList && _currentLevel > 0 && !_isSearching)
              GestureDetector(
                onTap: _goBack,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSearching && _searchQuery.isNotEmpty
                        ? 'Search Results'
                        : (_showList && _currentLevel > 0 
                            ? _getCurrentLevelTitle()
                            : 'User Location Dashboard'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isSearching && _searchQuery.isNotEmpty
                        ? '${_globalSearchResults.length} results for "$_searchQuery"'
                        : (_showList && _currentLevel == 3
                            ? '${_currentUsers.length} users found'
                            : '${_users.length} users registered'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'Map View',
              Icons.map,
              !_showList,
              () => setState(() {
                _showList = false;
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              }),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              'List View',
              Icons.list,
              _showList,
              () => setState(() {
                _showList = true;
                if (_currentLevel == 0) _loadStatesData();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _performGlobalSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Search across all locations and users...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                      _searchController.clear();
                      _globalSearchResults.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGlobalSearchResults() {
    if (_globalSearchResults.isEmpty) {
      return _buildEmptySearchState();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                return Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: crossAxisCount == 2 ? 3.5 : 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _globalSearchResults.length,
                    itemBuilder: (context, index) {
                      final result = _globalSearchResults[index];
                      return _buildSearchResultCard(result);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(dynamic result) {
    final type = result['type'];
    final name = result['name'] ?? (result['userData']?['name'] ?? 'Unknown');
    final icon = result['icon'];
    final color = result['color'];

    String subtitle = '';
    String userCount = '';

    if (type == 'user') {
      final userData = result['userData'];
      subtitle = '${userData['city'] ?? 'Unknown'}, ${userData['state'] ?? 'Unknown'}';
      userCount = userData['role']?.toString().toUpperCase() ?? 'USER';
    } else {
      switch (type) {
        case 'state':
          subtitle = 'State';
          userCount = '${result['userCount']} users';
          break;
        case 'city':
          subtitle = '${result['state']} State';
          userCount = '${result['userCount']} users';
          break;
        case 'area':
          subtitle = '${result['city']}, ${result['state']}';
          userCount = '${result['userCount']} users';
          break;
      }
    }

    return GestureDetector(
      onTap: () => _navigateFromSearch(result),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userCount,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for states, cities, areas, or user names',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 5.0,
            minZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.nearnest',
              maxZoom: 19,
            ),
            MarkerLayer(markers: _markers),
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMapControls(),
                  const Spacer(),
                  _buildMapLegend(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                icon: const Icon(Icons.add),
                color: const Color(0xFF3B82F6),
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[200],
              ),
              IconButton(
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                icon: const Icon(Icons.remove),
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _fitMarkersOnScreen,
            icon: const Icon(Icons.fit_screen),
            color: const Color(0xFF3B82F6),
            tooltip: 'Fit all markers',
          ),
        ),
      ],
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 6),
              const Text('Customers', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 6),
              const Text('Services', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 6),
              const Text('Shops', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          if (_currentLevel == 0) _buildLocationStats(),
          if (_currentLevel == 0) const SizedBox(height: 20),
          Expanded(child: _buildCurrentLevelList()),
        ],
      ),
    );
  }

  Widget _buildLocationStats() {
    final sortedStats = _locationStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...sortedStats.take(5).map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(stat.key)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${stat.value}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCurrentLevelList() {
    final filteredData = _getFilteredData();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getCurrentLevelTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty && !_isSearching)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredData.length} results',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filteredData.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                      return Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: crossAxisCount == 2 ? 2.5 : 1.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            if (_currentLevel == 3) {
                              return _buildUserCard(filteredData[index] as DocumentSnapshot);
                            } else {
                              final entry = filteredData[index] as MapEntry<String, Map<String, dynamic>>;
                              return _buildLocationCard(entry.key, entry.value);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String name, Map<String, dynamic> data) {
    IconData icon;
    String subtitle;
    
    switch (_currentLevel) {
      case 0: // States
        icon = Icons.map;
        subtitle = '${data['citiesCount'] ?? 0} cities';
        break;
      case 1: // Cities
        icon = Icons.location_city;
        subtitle = '${data['areasCount'] ?? 0} areas';
        break;
      case 2: // Areas/Pincodes
        icon = Icons.place;
        subtitle = '$_currentCity, $_currentState';
        break;
      default:
        icon = Icons.location_on;
        subtitle = '';
    }
    
    return GestureDetector(
      onTap: () => _navigateToLevel(_currentLevel + 1, name),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data['totalUsers'] ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if ((data['customer'] ?? 0) > 0)
                  _buildFullRoleChip('Customers', data['customer'] ?? 0, const Color(0xFF10B981)),
                if ((data['services'] ?? 0) > 0)
                  _buildFullRoleChip('Services', data['services'] ?? 0, const Color(0xFF3B82F6)),
                if ((data['shop'] ?? 0) > 0)
                  _buildFullRoleChip('Shops', data['shop'] ?? 0, const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullRoleChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompactRoleChip(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        count,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    final String role = userData['role'] ?? 'customer';
    final String streetAddress = userData['streetAddress'] ?? '';
    final String city = userData['city'] ?? 'Unknown';
    final String state = userData['state'] ?? 'Unknown';
    final String pincode = userData['pincode'] ?? '';
    
    // Build detailed address string
    String detailedAddress = '';
    if (streetAddress.isNotEmpty) {
      detailedAddress = streetAddress;
      if (city != 'Unknown') {
        detailedAddress += '\n$city';
        if (state != 'Unknown') {
          detailedAddress += ', $state';
        }
        if (pincode.isNotEmpty) {
          detailedAddress += ' - $pincode';
        }
      }
    } else {
      detailedAddress = '$city, $state';
      if (pincode.isNotEmpty) {
        detailedAddress += ' - $pincode';
      }
    }
    
    return GestureDetector(
      onTap: () => _showUserDetails(user),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getRoleColor(role),
                  child: Icon(
                    _getRoleIcon(role),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    detailedAddress,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userData['phone'].toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _fitMarkersOnScreen() {
    if (_markers.isEmpty) return;

    final latitudes = _markers.map((m) => m.point.latitude).toList();
    final longitudes = _markers.map((m) => m.point.longitude).toList();

    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLng = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }
}