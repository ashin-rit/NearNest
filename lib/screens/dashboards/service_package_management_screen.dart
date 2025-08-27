// lib/screens/dashboards/service_package_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/service_package_model.dart';

class ServicePackageManagementScreen extends StatefulWidget {
  const ServicePackageManagementScreen({super.key});

  @override
  State<ServicePackageManagementScreen> createState() => _ServicePackageManagementScreenState();
}

class _ServicePackageManagementScreenState extends State<ServicePackageManagementScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  ServicePackage? _editingPackage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to manage packages.')),
        );
        return;
      }

      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final int duration = int.tryParse(_durationController.text) ?? 0;

      try {
        if (_editingPackage == null) {
          // Add a new package
          final docRef = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('servicePackages')
              .add({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': price,
            'durationInMinutes': duration,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service package added successfully!')),
          );
        } else {
          // Update an existing package
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('servicePackages')
              .doc(_editingPackage!.id)
              .update({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'price': price,
            'durationInMinutes': duration,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service package updated successfully!')),
          );
          _clearForm();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save package: $e')),
        );
      }
    }
  }

  void _editPackage(ServicePackage package) {
    setState(() {
      _editingPackage = package;
      _nameController.text = package.name;
      _descriptionController.text = package.description;
      _priceController.text = package.price.toString();
      _durationController.text = package.durationInMinutes.toString();
    });
  }

  void _clearForm() {
    setState(() {
      _editingPackage = null;
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _durationController.clear();
    });
  }

  Future<void> _deletePackage(String packageId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('servicePackages')
          .doc(packageId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service package deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete package: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to manage your services.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildPackageList(user.uid),
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editingPackage == null ? 'Add New Service Package' : 'Edit Service Package',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                label: 'Service Name',
                validator: (value) => value!.isEmpty ? 'Please enter a name.' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _priceController,
                label: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty || double.tryParse(value) == null ? 'Please enter a valid price.' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _durationController,
                label: 'Duration (in minutes)',
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty || int.tryParse(value) == null ? 'Please enter a valid duration.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _savePackage,
                icon: Icon(_editingPackage == null ? Icons.add : Icons.save),
                label: Text(_editingPackage == null ? 'Add Service' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              if (_editingPackage != null)
                TextButton(
                  onPressed: _clearForm,
                  child: const Text('Cancel Edit'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int? maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPackageList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('servicePackages')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have not added any service packages yet.'));
        }

        final packages = snapshot.data!.docs
            .map((doc) => ServicePackage.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Current Service Packages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(package.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price: ₹${package.price.toStringAsFixed(2)}'),
                        Text('Duration: ${package.durationInMinutes} mins'),
                        Text('Description: ${package.description}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editPackage(package),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePackage(package.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}