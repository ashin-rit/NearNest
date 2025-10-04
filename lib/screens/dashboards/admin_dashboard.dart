// lib/screens/dashboards/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/dashboards/user_management_screen.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/login/admin_login_page.dart';
import 'package:nearnest/screens/dashboards/analytics_dashboard.dart';
import 'package:nearnest/screens/dashboards/admin_booking_management_screen.dart';
import 'package:nearnest/screens/dashboards/admin_notification_screen.dart';
import 'package:nearnest/screens/dashboards/admin_order_management_screen.dart';
import 'package:nearnest/screens/admin_user_location_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
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
      duration: const Duration(milliseconds: 1000),
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

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF60A5FA),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFF1F2937)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No users found.',
                  style: TextStyle(color: Color(0xFF1F2937)),
                ),
              );
            }

            final allUsers = snapshot.data!.docs;
            final int totalUsers = allUsers.length;
            final int customerCount =
                allUsers.where((doc) => doc['role'] == 'Customer').length;
            final int shopCount =
                allUsers.where((doc) => doc['role'] == 'Shop').length;
            final int serviceProviderCount =
                allUsers.where((doc) => doc['role'] == 'Services').length;

            return CustomScrollView(
              slivers: [
                // Custom Header
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1)
                                              .withOpacity(0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.dashboard_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Panel',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Control Center',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.power_settings_new_rounded,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: _logout,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome Back, Administrator',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'All systems operational',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Statistics
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.2, 1.0,
                            curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Platform Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.3,
                            children: [
                              _buildStatCard(
                                title: 'Total Users',
                                count: totalUsers,
                                icon: Icons.people_rounded,
                                iconColor: const Color(0xFF60A5FA),
                                numberColor: const Color(0xFF60A5FA),
                              ),
                              _buildStatCard(
                                title: 'Customers',
                                count: customerCount,
                                icon: Icons.person_outline_rounded,
                                iconColor: const Color(0xFF34D399),
                                numberColor: const Color(0xFF34D399),
                              ),
                              _buildStatCard(
                                title: 'Shops',
                                count: shopCount,
                                icon: Icons.store_rounded,
                                iconColor: const Color(0xFFFBBF24),
                                numberColor: const Color(0xFFFBBF24),
                              ),
                              _buildStatCard(
                                title: 'Services',
                                count: serviceProviderCount,
                                icon: Icons.work_outline_rounded,
                                iconColor: const Color(0xFFA78BFA),
                                numberColor: const Color(0xFFA78BFA),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Quick Actions
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.4, 1.0,
                            curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color numberColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: numberColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Manage Users',
        'subtitle': 'View and control accounts',
        'icon': Icons.manage_accounts_rounded,
        'iconColor': const Color(0xFF6366F1),
      },
      {
        'title': 'User Locations',
        'subtitle': 'Track user distribution',
        'icon': Icons.location_on_rounded,
        'iconColor': const Color(0xFF3B82F6),
      },
      {
        'title': 'Bookings',
        'subtitle': 'Service appointments',
        'icon': Icons.event_available_rounded,
        'iconColor': const Color(0xFF10B981),
      },
      {
        'title': 'Orders',
        'subtitle': 'Product transactions',
        'icon': Icons.shopping_bag_rounded,
        'iconColor': const Color(0xFFF59E0B),
      },
      {
        'title': 'Analytics',
        'subtitle': 'Performance insights',
        'icon': Icons.trending_up_rounded,
        'iconColor': const Color(0xFFEC4899),
      },
      {
        'title': 'Notifications',
        'subtitle': 'Broadcast messages',
        'icon': Icons.campaign_rounded,
        'iconColor': const Color(0xFF06B6D4),
      },
    ];

    final routes = [
      () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const UserManagementScreen()),
      ),
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminUserLocationDashboard(),
        ),
      ),
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminBookingManagementScreen(),
        ),
      ),
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminOrderManagementScreen(),
        ),
      ),
      () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnalyticsDashboard()),
      ),
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminNotificationScreen(),
        ),
      ),
    ];

    return Column(
      children: List.generate(
        actions.length,
        (index) => _buildActionCard(actions[index], routes[index]),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, VoidCallback onTap) {
    final Color iconColor = action['iconColor'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action['icon'], color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action['subtitle'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}