// lib/screens/dashboards/service_provider_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/dashboards/service_provider_profile_edit_screen.dart';
import 'package:nearnest/screens/dashboards/service_package_management_screen.dart'; // Import the new screen
import 'package:nearnest/screens/dashboards/service_provider_bookings_screen.dart'; 
import 'package:nearnest/screens/login_page.dart';// Import the bookings screen

class ServiceProviderDashboard extends StatefulWidget {
  const ServiceProviderDashboard({super.key});

  @override
  State<ServiceProviderDashboard> createState() => _ServiceProviderDashboardState();
}

class _ServiceProviderDashboardState extends State<ServiceProviderDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  DocumentSnapshot? _providerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
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
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load provider data.')),
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
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_providerData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Service Provider data not found.'),
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
      appBar: AppBar(
        title: Text('Service Dashboard: $name'),
        backgroundColor: const Color(0xFF0EA5E9),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Wait for the user to return from the edit screen
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceProviderProfileEditScreen(
                    userId: _auth.currentUser!.uid,
                    initialData: data,
                  ),
                ),
              );
              // Re-fetch data to update the dashboard
              _fetchProviderData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context), // Use the new _signOut method
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(context, name, email, phone,category, streetAddress, city, state, pincode, description),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context,
      String name,
      String email,
      String phone,
      String category,
      String streetAddress,
      String city,
      String state,
      String pincode,
      String description) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              Icons.person,
              'Name',
              name,
            ),
            _buildInfoRow(
              Icons.email,
              'Email',
              email,
            ),
            _buildInfoRow(
              Icons.phone,
              'Phone',
              phone,
            ),
            _buildInfoRow(
              Icons.category,
              'Category',
              category,
            ),
            _buildInfoRow(
              Icons.location_on,
              'Street Address',
              streetAddress,
              isMultiLine: true,
            ),
            _buildInfoRow(
              Icons.location_city,
              'City',
              city,
              isMultiLine: true,
            ),
            _buildInfoRow(
              Icons.map,
              'State',
              state,
              isMultiLine: true,
            ),
            _buildInfoRow(
              Icons.pin_drop,
              'Pincode',
              pincode,
              isMultiLine: true,
            ),
            _buildInfoRow(
              Icons.description,
              'Description',
              description,
              isMultiLine: true,
            ),
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
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment:
        isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today, color: Colors.blue),
          title: const Text('Manage Bookings'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ServiceProviderBookingsScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.business_center, color: Colors.green),
          title: const Text('Manage Services'), // New button
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ServicePackageManagementScreen()), // Navigate to the new screen
            );
          },
        ),
      ],
    );
  }
}