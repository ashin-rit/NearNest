// lib/screens/dashboards/user_profile_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'user_profile_edit_screen.dart'; // Import the new screen

class UserProfileView extends StatelessWidget {
  final String userId;
  final String userRole;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final userData = (await authService.getUserDataByUid(userId)).data() as Map<String, dynamic>;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileEditScreen(userId: userId, userData: userData),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: authService.getUserDataByUid(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = userData['name'] ?? 'N/A';
          final String email = userData['email'] ?? 'N/A';
          final String phone = userData['phone'] ?? 'N/A';
          final String address = userData['address'] ?? 'N/A';
          final String status = userData['status'] ?? 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(name, email, userRole),
                const SizedBox(height: 20),
                _buildProfileInfo(Icons.phone, 'Phone Number', phone),
                _buildProfileInfo(Icons.home, 'Address', address),
                _buildProfileInfo(Icons.assignment_ind, 'Status', status),
                const SizedBox(height: 30),
                _buildActionButtons(context, status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String role) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFB91C1C),
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 5),
        Chip(
          label: Text(
            role,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _getRoleColor(role),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB91C1C)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'pending')
          ElevatedButton.icon(
            onPressed: () => _updateUserStatus(context, 'approved'),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Approve', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        if (status == 'approved')
          ElevatedButton.icon(
            onPressed: () => _updateUserStatus(context, 'pending'),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('Decline', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
      ],
    );
  }

  void _updateUserStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to "$newStatus".'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Customer':
        return const Color(0xFF34D399);
      case 'Shop':
        return const Color(0xFFFACC15);
      case 'Services':
        return const Color(0xFF38BDF8);
      default:
        return Colors.grey;
    }
  }
}