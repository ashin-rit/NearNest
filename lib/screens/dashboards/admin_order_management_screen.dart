import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  String _selectedStatus = 'All';
  bool _sortAscending = false; // Default to descending for newest orders first

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
    'Delivered',
    'Picked Up',
  ];

  @override
  Widget build(BuildContext context) {
    // The query now fetches all orders to be filtered and sorted locally
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: const Color(0xFFB91C1C),
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
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
              child: StreamBuilder<QuerySnapshot>(
                // Stream now listens to ALL orders
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No orders found.'));
                  }

                  // Local filtering of documents
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final status = doc.data() as Map<String, dynamic>;
                    if (_selectedStatus == 'All') {
                      return true;
                    }
                    return status['status'] == _selectedStatus;
                  }).toList();

                  // Local sorting of documents
                  filteredDocs.sort((a, b) {
                    // Use a fallback to Timestamp.now() if orderDate is null
                    final aTimestamp = (a.data() as Map<String, dynamic>)['orderDate'] as Timestamp? ?? Timestamp.now();
                    final bTimestamp = (b.data() as Map<String, dynamic>)['orderDate'] as Timestamp? ?? Timestamp.now();
                    
                    if (_sortAscending) {
                      return aTimestamp.compareTo(bTimestamp);
                    } else {
                      return bTimestamp.compareTo(aTimestamp);
                    }
                  });

                  if (filteredDocs.isEmpty) {
                    return Center(child: Text('No $_selectedStatus orders found.'));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final orderDoc = filteredDocs[index];
                      final order = orderDoc.data() as Map<String, dynamic>;
                      final String orderId = orderDoc.id;
                      final String customerId = order['userId'] ?? '';
                      final String shopId = order['shopId'] ?? '';
                      final double totalAmount = (order['total'] as num?)?.toDouble() ?? 0.0;
                      final String status = order['status'] ?? 'N/A';
                      final Timestamp orderTimestamp = order['orderDate'] ?? Timestamp.now();
                      final String remarks = order['remarks'] ?? '';
                      final String cancelReason = order['cancellationReason'] ?? '';
                      final List<dynamic> items = order['items'] ?? [];

                      return FutureBuilder<Map<String, String>>(
                        future: _fetchNames(customerId, shopId),
                        builder: (context, namesSnapshot) {
                          if (!namesSnapshot.hasData) {
                            return Container();
                          }
                          final Map<String, String> names = namesSnapshot.data!;
                          final String customerName = names['customerName'] ?? 'Unknown Customer';
                          final String shopName = names['shopName'] ?? 'Unknown Shop';

                          // Extracting product names and quantities
                          final String productNames = items
                              .map((item) => '${item['name']} x ${item['quantity']}')
                              .join(', ');

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order ID
                                  Text(
                                    'Order ID: $orderId',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),

                                  // Customer and Shop Name
                                  Text('Customer: $customerName'),
                                  Text('Shop: $shopName'),
                                  const SizedBox(height: 8),

                                  // Product Names & Quantity
                                  Text(
                                    'Products: $productNames',
                                  ),
                                  const SizedBox(height: 8),

                                  // Total Amount
                                  Text(
                                    'Total Amount: ${totalAmount.toStringAsFixed(2)}',
                                  ),

                                  // Order Time
                                  Text(
                                    'Time: ${DateFormat('dd MMM yyyy hh:mm a').format(orderTimestamp.toDate())}',
                                  ),

                                  // Status
                                  Text(
                                    'Status: $status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(status),
                                    ),
                                  ),

                                  // Display remarks or cancellation reason
                                  if (status == 'Confirmed' && remarks.isNotEmpty)
                                    Text('Remarks: $remarks'),
                                  if (status == 'Canceled' && cancelReason.isNotEmpty)
                                    Text('Cancellation Reason: $cancelReason'),
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
      ),
    );
  }

  /// Fetches the customer and shop names for the order.
  Future<Map<String, String>> _fetchNames(String customerId, String shopId) async {
    final Map<String, String> names = {};
    
    // Fetch customer name
    if (customerId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      names['customerName'] = customerDoc.exists ? (customerDoc.data()?['name'] ?? 'N/A') : 'Unknown Customer';
    } else {
      names['customerName'] = 'Unknown Customer';
    }

    // Fetch shop name
    if (shopId.isNotEmpty) {
      final shopDoc = await FirebaseFirestore.instance.collection('users').doc(shopId).get();
      names['shopName'] = shopDoc.exists ? (shopDoc.data()?['name'] ?? 'N/A') : 'Unknown Shop';
    } else {
      names['shopName'] = 'Unknown Shop';
    }

    return names;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      case 'Delivered':
        return Colors.blue;
      case 'Picked Up':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}