// lib/screens/dashboards/service_provider_profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;

  const ServiceProviderProfileEditScreen({
    super.key,
    required this.userId,
    required this.initialData,
  });

  @override
  State<ServiceProviderProfileEditScreen> createState() => _ServiceProviderProfileEditScreenState();
}

class _ServiceProviderProfileEditScreenState extends State<ServiceProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _businessHoursController;

  final List<String> _categories = [
    'Plumber',
    'Doctor',
    'Tutor',
    'Electrician',
    'Painter',
    'Carpenter',
  ];
  late String _selectedCategory;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _phoneController = TextEditingController(text: widget.initialData['phone']);
    _addressController = TextEditingController(text: widget.initialData['address']);
    _descriptionController = TextEditingController(text: widget.initialData['description']);
    _businessHoursController = TextEditingController(text: widget.initialData['businessHours'] ?? '');
    _selectedCategory = widget.initialData['category'] ?? _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _businessHoursController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'businessHours': _businessHoursController.text.trim(),
        'category': _selectedCategory,
      };

      try {
        await _authService.updateUserData(widget.userId, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Service Provider Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Contact Number',
                icon: Icons.phone,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a contact number.' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 3,
                validator: (value) =>
                value!.isEmpty ? 'Please enter an address.' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _businessHoursController,
                label: 'Business Hours (e.g., Mon-Fri, 9 AM - 5 PM)',
                icon: Icons.access_time,
                validator: (value) =>
                value!.isEmpty ? 'Please enter your business hours.' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description of Services',
                icon: Icons.description,
                maxLines: 5,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a description.' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Service Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) =>
                value == null ? 'Please select a category.' : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }
}