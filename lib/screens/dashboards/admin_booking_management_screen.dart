import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() =>
      _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState
    extends State<AdminBookingManagementScreen> {
  String _selectedStatus = 'All';
  bool _sortAscending = true;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
  ];

  /// A stream that fetches all bookings and their associated user details
  /// to avoid multiple nested FutureBuilders, improving performance.
  Stream<List<Map<String, dynamic>>> _fetchBookingsWithDetails() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('bookings');

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    query = query.orderBy('bookingTime', descending: _sortAscending);

    return query.snapshots().asyncMap((snapshot) async {
      final List<Map<String, dynamic>> detailedBookings = [];
      for (var bookingDoc in snapshot.docs) {
        final bookingData = bookingDoc.data();
        final String customerId = bookingData['userId'] ?? '';
        final String serviceProviderId = bookingData['serviceProviderId'] ?? '';

        String customerName = 'Unknown Customer';
        String serviceProviderName = 'Unknown Provider';
        String serviceProviderCategory = 'N/A';
        
        // Fetch customer name
        if (customerId.isNotEmpty) {
          final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
          if (customerDoc.exists) {
            customerName = customerDoc.data()?['name'] ?? 'N/A';
          }
        }

        // Fetch service provider name and category
        if (serviceProviderId.isNotEmpty) {
          final providerDoc = await FirebaseFirestore.instance.collection('users').doc(serviceProviderId).get();
          if (providerDoc.exists) {
            serviceProviderName = providerDoc.data()?['name'] ?? 'N/A';
            serviceProviderCategory = providerDoc.data()?['category'] ?? 'N/A';
          }
        }
        
        detailedBookings.add({
          'id': bookingDoc.id,
          ...bookingData,
          'customerName': customerName,
          'serviceProviderName': serviceProviderName,
          'serviceProviderCategory': serviceProviderCategory,
        });
      }
      return detailedBookings;
    });
  }

  /// Determines the color of the status text.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        backgroundColor: const Color(0xFFB91C1C),
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Segmented Button for Status Filtering
            SegmentedButton<String>(
              segments: _statusOptions
                  .map((status) => ButtonSegment<String>(
                        value: status,
                        label: Text(status),
                      ))
                  .toList(),
              selected: {_selectedStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedStatus = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchBookingsWithDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No bookings found.'));
                  }
                  final detailedBookings = snapshot.data!;
                  return ListView.builder(
                    itemCount: detailedBookings.length,
                    itemBuilder: (context, index) {
                      final booking = detailedBookings[index];
                      final String bookingId = booking['id'];
                      final String? serviceName = booking['serviceName'];
                      final double? servicePrice = (booking['servicePrice'] as num?)?.toDouble();
                      final String? status = booking['status'];
                      final String? remarks = booking['remarks'];
                      final String? cancelReason = booking['cancellationReason'];
                      final Timestamp? bookingTime = booking['bookingTime'];
                      final String customerName = booking['customerName'];
                      final String serviceProviderName = booking['serviceProviderName'];
                      final String serviceProviderCategory = booking['serviceProviderCategory'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Booking ID at the top
                              Text(
                                'Booking ID: $bookingId',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),

                              // Service Category
                              Text(
                                'Service: $serviceProviderCategory',
                                style: const TextStyle(fontSize: 14),
                              ),

                              // Customer Name
                              Text(
                                'Customer: $customerName',
                                style: const TextStyle(fontSize: 14),
                              ),

                              // Service Provider Name
                              Text(
                                'Service Provider: $serviceProviderName',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),

                              // Service Name and Price
                              Text(
                                'Service Name: $serviceName - ₹${servicePrice?.toStringAsFixed(2) ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),

                              // Time
                              Text(
                                'Time: ${bookingTime != null ? DateFormat('dd MMM yyyy hh:mm a').format(bookingTime.toDate()) : 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),

                              // Status
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status ?? ''),
                                ),
                              ),

                              // Remarks / Cancellation Reason
                              if (status == 'Confirmed' && remarks != null && remarks.isNotEmpty)
                                Text('Remarks: $remarks'),
                              if (status == 'Canceled' && cancelReason != null && cancelReason.isNotEmpty)
                                Text('Cancellation Reason: $cancelReason'),
                            ],
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
      ),
    );
  }
}
