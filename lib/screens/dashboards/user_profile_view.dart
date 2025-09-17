// lib/screens/dashboards/user_profile_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/widgets/admin_reviews_section.dart';

class UserProfileView extends StatefulWidget {
  final String userId;
  final String userRole;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: authService.getUserDataByUid(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 3,
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return _buildErrorState();
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileContent(userData);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'User data not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> userData) {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Card
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              )),
              child: _buildProfileHeader(userData),
            ),
            const SizedBox(height: 24),
            // Content Cards
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutCubic,
              )),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildContactInfoCard(userData),
                    const SizedBox(height: 16),
                    _buildAddressCard(userData),
                    if (widget.userRole == 'Shop') ...[
                      const SizedBox(height: 16),
                      _buildShopDetailsCard(userData),
                    ],
                    if (widget.userRole == 'Services') ...[
                      const SizedBox(height: 16),
                      _buildServiceDetailsCard(userData),
                    ],
                    if (widget.userRole == 'Shop' || widget.userRole == 'Services') ...[
                      const SizedBox(height: 24),
                      _buildReviewsSection(userData),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final String name = userData['name'] ?? 'N/A';
    final String role = widget.userRole;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(role),
            _getRoleColor(role).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(role).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getRoleIcon(role),
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(Map<String, dynamic> userData) {
    final String email = userData['email'] ?? 'N/A';
    final String phone = userData['phone'] ?? 'N/A';

    return _buildInfoCard(
      title: 'Contact Information',
      icon: Icons.phone_rounded,
      children: [
        _buildInfoRow(Icons.email_rounded, 'Email Address', email),
        _buildInfoRow(Icons.phone_rounded, 'Phone Number', phone),
      ],
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> userData) {
    final String streetAddress = userData['streetAddress'] ?? 'N/A';
    final String city = userData['city'] ?? 'N/A';
    final String state = userData['state'] ?? 'N/A';
    final String pincode = userData['pincode'] ?? 'N/A';

    return _buildInfoCard(
      title: 'Address Information',
      icon: Icons.location_on_rounded,
      children: [
        _buildInfoRow(Icons.home_rounded, 'Street Address', streetAddress),
        _buildInfoRow(Icons.location_city_rounded, 'City', city),
        _buildInfoRow(Icons.map_rounded, 'State', state),
        _buildInfoRow(Icons.pin_drop_rounded, 'Pincode', pincode),
      ],
    );
  }

  Widget _buildShopDetailsCard(Map<String, dynamic> userData) {
    final bool isDeliveryAvailable = userData['isDeliveryAvailable'] ?? false;
    final String businessHours = userData['businessHours'] ?? 'N/A';
    final String category = userData['category'] ?? 'N/A';
    final String description = userData['description'] ?? 'N/A';

    return _buildInfoCard(
      title: 'Shop Details',
      icon: Icons.storefront_rounded,
      children: [
        _buildInfoRow(Icons.category_rounded, 'Category', category),
        _buildInfoRow(Icons.description_rounded, 'Description', description),
        _buildInfoRow(Icons.access_time_rounded, 'Business Hours', businessHours),
        _buildDeliveryRow(isDeliveryAvailable),
      ],
    );
  }

  Widget _buildServiceDetailsCard(Map<String, dynamic> userData) {
    final String category = userData['category'] ?? 'N/A';
    final String description = userData['description'] ?? 'N/A';

    return _buildInfoCard(
      title: 'Service Details',
      icon: Icons.business_center_rounded,
      children: [
        _buildInfoRow(Icons.category_rounded, 'Category', category),
        _buildInfoRow(Icons.description_rounded, 'Description', description),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6366F1),
                    size: 24,
                  ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryRow(bool isDeliveryAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDeliveryAvailable
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDeliveryAvailable
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDeliveryAvailable
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: isDeliveryAvailable
                            ? const Color(0xFF10B981)
                            : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDeliveryAvailable ? 'Available' : 'Not Available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDeliveryAvailable
                              ? const Color(0xFF10B981)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Customer':
        return Icons.person_rounded;
      case 'Shop':
        return Icons.storefront_rounded;
      case 'Services':
        return Icons.business_center_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildReviewsSection(Map<String, dynamic> userData) {
    final double averageRating = (userData['averageRating'] ?? 0.0).toDouble();
    final int reviewCount = userData['reviewCount'] ?? 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AdminReviewsSection(
          itemId: widget.userId,
          averageRating: averageRating,
          reviewCount: reviewCount,
        ),
      ),
    );
  }
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Customer':
        return const Color(0xFF10B981);
      case 'Shop':
        return const Color(0xFFF59E0B);
      case 'Services':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6B7280);
    }
  }
}