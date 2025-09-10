// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/login_page.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/user_profile_edit_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DocumentSnapshot? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userData = await _authService.getUserDataByUid(user.uid);
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Handle error, e.g., show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data.')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle the case where the user is not logged in
    }
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_userData == null) {
      return const Center(
        child: Text('User data not found.'),
      );
    }

    final data = _userData!.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String streetAddress = data['streetAddress'] ?? 'N/A';
    final String city = data['city'] ?? 'N/A';
    final String state = data['state'] ?? 'N/A';
    final String pincode = data['pincode'] ?? 'N/A';
    final String role = data['role'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileEditScreen(
                    userId: _auth.currentUser!.uid,
                    initialData: data,
                  ),
                ),
              );
              _fetchUserData(); // Refresh data after returning from edit screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Role: $role',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoCard(
                title: 'Email',
                value: email,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Phone',
                value: phone,
                icon: Icons.phone,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Street Address',
                value: streetAddress,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'City',
                value: city,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'State',
                value: state,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Pincode',
                value: pincode,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF34D399)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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