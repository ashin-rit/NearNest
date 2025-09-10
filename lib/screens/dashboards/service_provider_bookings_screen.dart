// lib/screens/dashboards/service_provider_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/models/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceProviderBookingsScreen extends StatefulWidget {
  const ServiceProviderBookingsScreen({super.key});

  @override
  State<ServiceProviderBookingsScreen> createState() => _ServiceProviderBookingsScreenState();
}

class _ServiceProviderBookingsScreenState extends State<ServiceProviderBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedStatus = 'All';
  bool _sortAscending = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
  ];

  @override
  void dispose() {
    _remarksController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus, {String? cancellationReason, String? remarks}) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus};
      if (remarks != null) {
        updateData['remarks'] = remarks;
      }
      if (cancellationReason != null) {
        updateData['cancellationReason'] = cancellationReason;
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $newStatus!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking status: $e'),
        ),
      );
    }
  }

  void _showBookingActionDialog(
      BuildContext context, String bookingId, String status, String? currentRemarks) {
    if (status == 'Pending') {
      _remarksController.text = currentRemarks ?? '';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pending Booking Actions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Add remarks for customer',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _updateBookingStatus(bookingId, 'Confirmed', remarks: _remarksController.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm Booking'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCancelDialog(context, bookingId);
                    },
                    child: const Text('Cancel Booking', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    _cancelReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: TextField(
            controller: _cancelReasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for cancellation',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Back'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_cancelReasonController.text.isNotEmpty) {
                  _updateBookingStatus(bookingId, 'Canceled', cancellationReason: _cancelReasonController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a cancellation reason.')),
                  );
                }
              },
              child: const Text('Confirm Cancellation', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<String> _fetchCustomerName(String userId) async {
    if (userId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return customerDoc.exists ? (customerDoc.data()?['name'] ?? 'N/A') : 'Unknown Customer';
    } else {
      return 'Unknown Customer';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID to filter bookings
    final String? serviceProviderId = _auth.currentUser?.uid;

    if (serviceProviderId == null) {
      return const Scaffold(
        body: Center(child: Text('Service Provider not logged in.')),
      );
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: serviceProviderId);

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    query = query.orderBy('bookingTime', descending: _sortAscending);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color.fromARGB(255, 230, 230, 230),
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_sortAscending
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontally scrollable row of filter tiles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _statusOptions.map((status) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: _getStatusColor(status).withOpacity(0.5),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: BorderSide(
                          color: _selectedStatus == status ? _getStatusColor(status) : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No bookings found.'));
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index].data() as Map<String, dynamic>;
                    final String bookingId = bookings[index].id;
                    final String status = booking['status'] ?? 'Unknown';
                    final String userId = booking['userId'] ?? 'Unknown';
                    final Timestamp bookingTime = booking['bookingTime'];
                    final String serviceName = booking['serviceName'] ?? 'Unknown Service';
                    final String? taskDescription = booking['taskDescription'];
                    final String? remarks = booking['remarks'];
                    final String? cancelReason = booking['cancellationReason'];

                    return FutureBuilder<String>(
                      future: _fetchCustomerName(userId),
                      builder: (context, customerSnapshot) {
                        final customerName = customerSnapshot.data ?? 'Fetching...';
                        return InkWell(
                          onTap: () {
                            if (status == 'Pending') {
                              _showBookingActionDialog(context, bookingId, status, remarks);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking ID: $bookingId',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Customer: $customerName'),
                                  Text(
                                      'Time: ${DateFormat('yyyy-MM-dd  kk:mm').format(bookingTime.toDate())}'),
                                  Text('Status: $status',
                                      style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold)),
                                  if (remarks != null && remarks.isNotEmpty)
                                    Text('Remarks: $remarks',
                                      style: const TextStyle(fontStyle: FontStyle.italic)),
                                  if (cancelReason != null && cancelReason.isNotEmpty)
                                    Text('Reason: $cancelReason',
                                      style: const TextStyle(fontStyle: FontStyle.italic)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Service Details:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey),
                                  ),
                                  Text(
                                    'Service: $serviceName',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                                  if (taskDescription != null && taskDescription.isNotEmpty)
                                    Text(
                                      'Task: $taskDescription',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}