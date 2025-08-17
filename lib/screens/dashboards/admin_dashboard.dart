// lib/screens/dashboards/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/dashboards/user_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFB91C1C), // Admin's primary color
        elevation: 0,
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
          final int customerCount = allUsers
              .where((doc) => doc['role'] == 'Customer')
              .length;
          final int shopCount = allUsers
              .where((doc) => doc['role'] == 'Shop')
              .length;
          final int serviceProviderCount = allUsers
              .where((doc) => doc['role'] == 'Service Provider')
              .length;
          final int adminCount = allUsers
              .where((doc) => doc['role'] == 'Admin')
              .length;

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
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.manage_accounts,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Manage All Users',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
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
}
