// lib/screens/dashboards/shop_profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;

  const ShopProfileEditScreen({
    super.key,
    required this.userId,
    required this.initialData,
  });

  @override
  State<ShopProfileEditScreen> createState() => _ShopProfileEditScreenState();
}

class _ShopProfileEditScreenState extends State<ShopProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _shopNameController;
  late TextEditingController _shopPhoneNumberController;
  late TextEditingController _shopAddressController;
  late TextEditingController _descriptionController;
  late TextEditingController _businessHoursController; // Added new controller

  final List<String> _categories = [
    'Grocery',
    'Clothing',
    'Electronics',
    'Restaurant',
    'Salon',
    'Pharmacy',
  ];
  late String _selectedCategory;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: widget.initialData['name']);
    _shopPhoneNumberController = TextEditingController(text: widget.initialData['phone']);
    _shopAddressController = TextEditingController(text: widget.initialData['address']);
    _descriptionController = TextEditingController(text: widget.initialData['description']);
    _businessHoursController = TextEditingController(text: widget.initialData['business_hours']); // Initialized new controller
    _selectedCategory = widget.initialData['category'] ?? _categories.first;
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopPhoneNumberController.dispose();
    _shopAddressController.dispose();
    _descriptionController.dispose();
    _businessHoursController.dispose(); // Added to dispose
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final updatedData = {
        'name': _shopNameController.text.trim(),
        'phone': _shopPhoneNumberController.text.trim(),
        'address': _shopAddressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'business_hours': _businessHoursController.text.trim(), // Added to updated data
        'category': _selectedCategory,
      };

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
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
        title: const Text('Edit Business Profile'),
        backgroundColor: const Color(0xFF854D0E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _shopNameController,
                label: 'Business Name',
                icon: Icons.store,
                validator: (value) => value!.isEmpty ? 'Name cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _shopPhoneNumberController,
                label: 'Phone Number',
                icon: Icons.phone,
                validator: (value) => value!.isEmpty ? 'Phone cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _shopAddressController,
                label: 'Address',
                icon: Icons.location_on,
                validator: (value) => value!.isEmpty ? 'Address cannot be empty.' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                validator: (value) => value!.isEmpty ? 'Description cannot be empty.' : null,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              // Added new: Business Hours field
              _buildTextField(
                controller: _businessHoursController,
                label: 'Business Hours',
                icon: Icons.access_time,
                validator: (value) => value!.isEmpty ? 'Business hours cannot be empty.' : null,
              ),
              const SizedBox(height: 16),
              // New: Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Please select a category.' : null,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF854D0E),
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