// lib/screens/update_location_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class UpdateLocationScreen extends StatefulWidget {
  final String userId;
  final String currentAddress;

  const UpdateLocationScreen({
    super.key,
    required this.userId,
    required this.currentAddress,
  });

  @override
  State<UpdateLocationScreen> createState() => _UpdateLocationScreenState();
}

class _UpdateLocationScreenState extends State<UpdateLocationScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.currentAddress;
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    final String address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a valid address.';
        _isLoading = false;
      });
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        setState(() {
          _statusMessage = 'Could not find coordinates for this address.';
          _isLoading = false;
        });
        return;
      }

      final Location firstLocation = locations.first;
      final GeoPoint geoPoint =
          GeoPoint(firstLocation.latitude, firstLocation.longitude);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'address': address,
        'location': geoPoint,
      });

      setState(() {
        _statusMessage = 'Location updated successfully!';
        _isLoading = false;
      });

      // Navigate back or show a success dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to update location: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Business Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateLocation,
                    child: const Text('Save Location'),
                  ),
            const SizedBox(height: 10),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.contains('successfully')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}