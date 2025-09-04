// lib/screens/dashboards/service_provider_profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ServiceProviderProfileEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;

  const ServiceProviderProfileEditScreen({
    Key? key,
    required this.userId,
    required this.initialData,
  }) : super(key: key);

  @override
  _ServiceProviderProfileEditScreenState createState() => _ServiceProviderProfileEditScreenState();
}

class _ServiceProviderProfileEditScreenState extends State<ServiceProviderProfileEditScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialData['name'] ?? '';
    _emailController.text = widget.initialData['email'] ?? '';
    _phoneController.text = widget.initialData['phone'] ?? '';
    _categoryController.text = widget.initialData['category'] ?? '';
    _streetAddressController.text = widget.initialData['streetAddress'] ?? '';
    _cityController.text = widget.initialData['city'] ?? '';
    _stateController.text = widget.initialData['state'] ?? '';
    _pincodeController.text = widget.initialData['pincode'] ?? '';
    _descriptionController.text = widget.initialData['description'] ?? '';
    
    final GeoPoint? location = widget.initialData['location'] as GeoPoint?;
    if (location != null) {
      _latitude = location.latitude;
      _longitude = location.longitude;
    } else {
      _latitude = widget.initialData['latitude'];
      _longitude = widget.initialData['longitude'];
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _streetAddressController.text = place.street ?? '';
        _cityController.text = place.locality ?? '';
        _categoryController.text = place.subAdministrativeArea ?? '';
        _stateController.text = place.administrativeArea ?? '';
        _pincodeController.text = place.postalCode ?? '';
        _latitude = position.latitude;
        _longitude = position.longitude;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final Map<String, dynamic> dataToUpdate = {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'category': _categoryController.text,
          'streetAddress': _streetAddressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
          'description': _descriptionController.text,
        };

        // Geocoding validation
        final fullAddress = '${_streetAddressController.text}, ${_cityController.text}, ${_stateController.text}, ${_pincodeController.text}';
        List<Location> locations = await locationFromAddress(fullAddress);
        
        if (locations.isNotEmpty) {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
          dataToUpdate['location'] = GeoPoint(_latitude!, _longitude!);
          dataToUpdate['latitude'] = _latitude;
          dataToUpdate['longitude'] = _longitude;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid address. Please enter a valid location.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await _authService.updateUserData(widget.userId, dataToUpdate);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop(true);
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
        title: const Text('Edit Service Provider Profile'),
        backgroundColor: const Color(0xFF0EA5E9),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(_nameController, 'Name'),
                    _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
                    _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone),
                    _buildTextField(_categoryController, 'Category'),
                    _buildTextField(_streetAddressController, 'Street Address'),
                    _buildTextField(_cityController, 'City'),
                    _buildTextField(_stateController, 'State'),
                    _buildTextField(_pincodeController, 'Pincode'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _updateLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Update to Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'Description', maxLines: 3),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the $label';
          }
          return null;
        },
      ),
    );
  }
}