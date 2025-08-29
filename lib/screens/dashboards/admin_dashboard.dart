// lib/screens/dashboards/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/dashboards/user_management_screen.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/login_page.dart';
import 'package:nearnest/screens/dashboards/analytics_dashboard.dart';
import 'package:nearnest/screens/dashboards/admin_booking_management_screen.dart';
import 'package:nearnest/screens/dashboards/admin_notification_screen.dart';
import 'package:nearnest/screens/dashboards/admin_order_management_screen.dart'; // Import the new screen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final allUsers = snapshot.data!.docs;
          final int totalUsers = allUsers.length;
          final int customerCount =
              allUsers.where((doc) => doc['role'] == 'Customer').length;
          final int shopCount =
              allUsers.where((doc) => doc['role'] == 'Shop').length;
          final int serviceProviderCount =
              allUsers.where((doc) => doc['role'] == 'Services').length;
          final int adminCount =
              allUsers.where((doc) => doc['role'] == 'Admin').length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Quick overview of your application.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                _buildOverviewCard(
                  title: 'Total Users',
                  count: totalUsers,
                  icon: Icons.group,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                _buildOverviewCard(
                  title: 'Customers',
                  count: customerCount,
                  icon: Icons.people_outline,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildOverviewCard(
                  title: 'Shops',
                  count: shopCount,
                  icon: Icons.store,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildOverviewCard(
                  title: 'Service Providers',
                  count: serviceProviderCount,
                  icon: Icons.business_center,
                  color: Colors.cyan,
                ),
                const SizedBox(height: 16),
                _buildOverviewCard(
                  title: 'Admins',
                  count: adminCount,
                  icon: Icons.security,
                  color: const Color(0xFFB91C1C),
                ),
                const SizedBox(height: 40),
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.manage_accounts, color: Color(0xFFB91C1C)),
          title: const Text('Manage All Users'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserManagementScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.bar_chart, color: Colors.blue),
          title: const Text('Analytics & Reports'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AnalyticsDashboard(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.purple),
          title: const Text('Manage All Bookings'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminBookingManagementScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.shopping_cart, color: Colors.teal),
          title: const Text('Manage All Orders'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminOrderManagementScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.notifications_active, color: Colors.indigo),
          title: const Text('Send Notifications'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminNotificationScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}