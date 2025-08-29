// lib/screens/dashboards/admin_service_package_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminServicePackageManagementScreen extends StatefulWidget {
  const AdminServicePackageManagementScreen({super.key});

  @override
  State<AdminServicePackageManagementScreen> createState() =>
      _AdminServicePackageManagementScreenState();
}

class _AdminServicePackageManagementScreenState
    extends State<AdminServicePackageManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showPackageDialog({DocumentSnapshot? doc}) async {
    final TextEditingController nameController =
        TextEditingController(text: doc?['name'] ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: doc?['description'] ?? '');
    final TextEditingController priceController =
        TextEditingController(text: doc?['price']?.toString() ?? '');
    final TextEditingController serviceProviderIdController =
        TextEditingController(text: doc?['serviceProviderId'] ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? 'Add Service Package' : 'Edit Service Package'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: serviceProviderIdController,
                  decoration: const InputDecoration(labelText: 'Service Provider ID'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text;
                final String description = descriptionController.text;
                final double price = double.tryParse(priceController.text) ?? 0.0;
                final String serviceProviderId = serviceProviderIdController.text;

                if (name.isNotEmpty && price > 0 && serviceProviderId.isNotEmpty) {
                  try {
                    if (doc == null) {
                      await _firestore.collection('service_packages').add({
                        'name': name,
                        'description': description,
                        'price': price,
                        'serviceProviderId': serviceProviderId,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Package added successfully!')),
                        );
                      }
                    } else {
                      await _firestore.collection('service_packages').doc(doc.id).update({
                        'name': name,
                        'description': description,
                        'price': price,
                        'serviceProviderId': serviceProviderId,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Package updated successfully!')),
                        );
                      }
                    }
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save package: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      await _firestore.collection('service_packages').doc(packageId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete package: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String packageId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Service Package?'),
          content: const Text('Are you sure you want to delete this service package? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm) {
      _deletePackage(packageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Service Packages'),
        backgroundColor: const Color(0xFFB91C1C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('service_packages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No service packages found.'));
          }

          final packages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final doc = packages[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text(
                      'Price: \$${(data['price'] ?? 0.0).toStringAsFixed(2)}\n'
                      'Provider ID: ${data['serviceProviderId'] ?? 'N/A'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showPackageDialog(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPackageDialog(),
        backgroundColor: const Color(0xFFB91C1C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}