import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/dashboards/service_provider_profile_edit_screen.dart';
import 'package:nearnest/screens/dashboards/service_package_management_screen.dart';
import 'package:nearnest/screens/dashboards/service_provider_bookings_screen.dart';
import 'package:nearnest/screens/review_management_screen.dart';
import 'package:nearnest/screens/login/service_provider_login_page.dart';

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  DocumentSnapshot? _providerData;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fetchProviderData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final providerData = await _authService.getUserDataByUid(user.uid);
        setState(() {
          _providerData = providerData;
          _isLoading = false;
        });
        _fadeController.forward();
        _slideController.forward();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load provider data.'),
            backgroundColor: const Color(0xFF0EA5E9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ServiceProviderLoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_providerData == null || !_providerData!.exists) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Service Provider data not found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _providerData!.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String category = data['category'] ?? 'N/A';
    final String streetAddress = data['streetAddress'] ?? 'N/A';
    final String city = data['city'] ?? 'N/A';
    final String state = data['state'] ?? 'N/A';
    final String pincode = data['pincode'] ?? 'N/A';
    final String description = data['description'] ?? 'No description provided.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0EA5E9).withOpacity(0.1),
                      const Color(0xFF38BDF8).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                  onPressed: () => _signOut(context),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOutCubic,
                    )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 32),
                        _buildQuickActions(),
                        const SizedBox(height: 32),
                        _buildServiceDetails(data),
                        const SizedBox(height: 24),
                        _buildContactInfo(email, phone, streetAddress, city, state, pincode),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grow your professional service business',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Edit Profile',
                Icons.edit_rounded,
                const Color(0xFF10B981),
                () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ServiceProviderProfileEditScreen(
                        userId: _auth.currentUser!.uid,
                        initialData: _providerData!.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                  _fetchProviderData();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Manage Services',
                Icons.handyman_rounded,
                const Color(0xFF3B82F6),
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ServicePackageManagementScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Manage Bookings',
                Icons.calendar_today_rounded,
                const Color(0xFFF59E0B),
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ServiceProviderBookingsScreen(),
                    ),
                  );
                },
                isWide: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Manage Reviews',
                Icons.reviews_rounded,
                const Color(0xFF8B5CF6),
                () {
                  final data = _providerData!.data() as Map<String, dynamic>;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReviewManagementScreen(
                        businessId: _auth.currentUser!.uid,
                        businessName: data['name'] ?? 'Your Service',
                      ),
                    ),
                  );
                },
                isWide: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap, {bool isWide = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isWide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildServiceDetails(Map<String, dynamic> data) {
    return _buildInfoCard(
      'Service Information',
      Icons.business_center_rounded,
      const Color(0xFF0EA5E9),
      [
        _buildInfoRow(Icons.person_rounded, 'Name', data['name'] ?? 'N/A'),
        _buildInfoRow(Icons.category_rounded, 'Category', data['category'] ?? 'N/A'),
        if (data['description'] != null && data['description'].isNotEmpty)
          _buildInfoRow(Icons.description_rounded, 'Description', data['description'], isMultiLine: true),
      ],
    );
  }

  Widget _buildContactInfo(String email, String phone, String streetAddress, String city, String state, String pincode) {
    return _buildInfoCard(
      'Contact Details',
      Icons.contact_mail_rounded,
      const Color(0xFF10B981),
      [
        _buildInfoRow(Icons.email_rounded, 'Email', email),
        _buildInfoRow(Icons.phone_rounded, 'Phone', phone),
        _buildInfoRow(Icons.location_on_rounded, 'Address', '$streetAddress, $city', isMultiLine: true),
        _buildInfoRow(Icons.map_rounded, 'Location', '$state - $pincode'),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData titleIcon, Color accentColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(titleIcon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiLine = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 16),
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
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}