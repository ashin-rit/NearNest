// lib/screens/dashboards/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/dashboards/user_profile_view.dart'; // Import the new screen

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
    'Pending Approval',
    'Customer',
    'Shop',
    'Services',
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

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User status updated to "$newStatus".')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  Future<void> _showConfirmationDialog(String userId, String action) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$action User?'),
          content: Text('Are you sure you want to $action this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action, style: TextStyle(color: action == 'Delete' || action == 'Decline' ? Colors.red : Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirm) {
      if (action == 'Delete') {
        _deleteUser(userId);
      } else {
        _updateUserStatus(userId, action == 'Approve' ? 'approved' : 'pending');
      }
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
                  final status = data['status'] ?? 'pending';

                  final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery);
                  final matchesRole = (_selectedRole == 'All' && role != 'Admin') || (_selectedRole == 'Pending Approval' && status == 'pending' && (role == 'Shop' || role == 'Services')) || (_selectedRole == role && role != 'Admin');

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
                    final String status = data['status'] ?? 'pending';

                    final bool isAccountToggleable = (role == 'Shop' || role == 'Services');
                    final bool isPending = status == 'pending';

                    final List<Widget> trailingButtons = [];
                    if (isAccountToggleable) {
                      if (isPending) {
                        trailingButtons.add(
                          ElevatedButton(
                            onPressed: () => _showConfirmationDialog(doc.id, 'Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Approve', style: TextStyle(color: Colors.white)),
                          ),
                        );
                      } else {
                        trailingButtons.add(
                          ElevatedButton(
                            onPressed: () => _showConfirmationDialog(doc.id, 'Decline'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Decline', style: TextStyle(color: Colors.white)),
                          ),
                        );
                      }
                    } else if (role == 'Customer') {
                      trailingButtons.add(
                        ElevatedButton(
                          onPressed: () => _showConfirmationDialog(doc.id, 'Delete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }

                    if (trailingButtons.isNotEmpty) {
                      trailingButtons.add(const SizedBox(width: 8));
                    }
                    trailingButtons.add(
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfileView(userId: doc.id, userRole: role),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('Details', style: TextStyle(color: Colors.white)),
                      ),
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email),
                            const SizedBox(height: 4),
                            Text(
                              isAccountToggleable
                                  ? isPending ? 'Status: Pending' : 'Status: Approved'
                                  : 'Role: $role',
                              style: TextStyle(
                                color: isAccountToggleable ? (isPending ? Colors.orange : Colors.green) : _getRoleColor(role),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role),
                          child: Icon(_getRoleIcon(role), color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: trailingButtons,
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
      default:
        return Colors.grey;
    }
  }
}   