// lib/screens/dashboards/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';

  final List<String> _roles = [
    'All',
    'Customer',
    'Shop',
    'Services',
    'Admin'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _updateUserStatus(String userId, bool isApproved) async {
    final newStatus = isApproved ? 'approved' : 'pending';
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User status updated to "$newStatus".')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage All Users'),
        backgroundColor: const Color(0xFFB91C1C),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final role = _roles[index];
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    selectedColor: const Color(0xFFB91C1C),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedRole = selected ? role : 'All';
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toLowerCase() ?? '';
                  final email = data['email']?.toLowerCase() ?? '';
                  final role = data['role'] ?? 'N/A';

                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery);
                  final matchesRole = _selectedRole == 'All' || role == _selectedRole;

                  return matchesSearch && matchesRole;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching users found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String name = data['name'] ?? 'N/A';
                    final String email = data['email'] ?? 'N/A';
                    final String role = data['role'] ?? 'N/A';
                    final String status = data['status'] ?? 'N/A';
                    final bool isApproved = status == 'approved';
                    final bool isAccountToggleable = (role == 'Shop' || role == 'Services');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile(
                        value: isApproved,
                        onChanged: isAccountToggleable ? (value) => _updateUserStatus(doc.id, value) : null,
                        activeColor: Colors.green,
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            Text(
                              isAccountToggleable
                                ? isApproved ? 'Approved' : 'Pending'
                                : 'Role: $role (Auto-Approved)',
                              style: TextStyle(
                                color: isApproved ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: _getRoleColor(role),
                          child: Icon(_getRoleIcon(role), color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Customer':
        return Icons.person;
      case 'Shop':
        return Icons.store;
      case 'Services':
        return Icons.business_center;
      case 'Admin':
        return Icons.security;
      default:
        return Icons.help_outline;
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
      case 'Admin':
        return const Color(0xFFB91C1C);
      default:
        return Colors.grey;
    }
  }
}