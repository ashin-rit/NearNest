// lib/screens/dashboards/admin_booking_management_screen.dart
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

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('bookings');

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    query = query.orderBy('bookingTime', descending: _sortAscending);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        backgroundColor: const Color(0xFFB91C1C),
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            tooltip: 'Sort by date',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _statusOptions.map((status) {
                  final isSelected = _selectedStatus == status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: const Color(0xFFB91C1C),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
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
                    final doc = bookings[index];
                    final data = doc.data() as Map<String, dynamic>?;

                    if (data == null) {
                      return const SizedBox.shrink();
                    }

                    final String serviceName = data['serviceName'] ?? 'Unknown Service';
                    final Timestamp bookingTime = data['bookingTime'] as Timestamp? ?? Timestamp.now();
                    final String status = data['status'] ?? 'Pending';
                    final String serviceProviderId = data['serviceProviderId'] ?? '';
                    final String userId = data['userId'] ?? '';

                    String details = 'N/A';
                    if (status == 'Confirmed') {
                      details = data['remarks'] ?? 'No remarks provided';
                    } else if (status == 'Canceled') {
                      details = data['cancellationReason'] ?? 'No reason provided';
                    }

                    return FutureBuilder<Map<String, String>>(
                      future: _fetchNames(userId, serviceProviderId),
                      builder: (context, nameSnapshot) {
                        if (nameSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading user details...'),
                          );
                        }
                        if (nameSnapshot.hasError) {
                          return ListTile(
                            title: Text('Error loading names: ${nameSnapshot.error}'),
                            subtitle: const Text('One or more user IDs are invalid.'),
                          );
                        }

                        final names = nameSnapshot.data!;
                        final customerName = names['customerName'] ?? 'Unknown Customer';
                        final serviceProviderName = names['serviceProviderName'] ?? 'Unknown Provider';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service: $serviceName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text('Customer: $customerName'),
                                Text('Service Provider: $serviceProviderName'),
                                Text('Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(bookingTime.toDate())}'),
                                Text('Status: $status', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                                Text('${status == 'Confirmed' ? 'Remarks' : 'Reason'}: $details'),
                              ],
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

  Future<Map<String, String>> _fetchNames(String customerId, String serviceProviderId) async {
    final Map<String, String> names = {};
    
    if (customerId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      names['customerName'] = customerDoc.exists ? (customerDoc.data()?['name'] ?? 'N/A') : 'Unknown Customer';
    } else {
      names['customerName'] = 'Unknown Customer';
    }

    if (serviceProviderId.isNotEmpty) {
      final serviceProviderDoc = await FirebaseFirestore.instance.collection('users').doc(serviceProviderId).get();
      names['serviceProviderName'] = serviceProviderDoc.exists ? (serviceProviderDoc.data()?['name'] ?? 'N/A') : 'Unknown Provider';
    } else {
      names['serviceProviderName'] = 'Unknown Provider';
    }

    return names;
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
}