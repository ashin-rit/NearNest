// lib/screens/dashboards/admin_order_management_screen.dart
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
  bool _sortAscending = true;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
    'Delivered',
    'Picked Up', // Added the 'Picked Up' status
  ];

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('orders');

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    query = query.orderBy('orderDate', descending: _sortAscending);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: const Color(0xFFB91C1C),
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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
                  return const Center(child: Text('No orders found.'));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>?;

                    if (data == null) {
                      return const SizedBox.shrink();
                    }

                    final String shopId = data['shopId'] ?? '';
                    final String userId = data['userId'] ?? '';
                    final Timestamp orderDate = data['orderDate'] as Timestamp? ?? Timestamp.now();
                    final String status = data['status'] ?? 'Pending';
                    final String orderId = doc.id;

                    String details = 'N/A';
                    final bool isDelivery = data['isDelivery'] ?? false;
                    final List<dynamic> items = data['items'] ?? [];
                    
                    if (status == 'Confirmed') {
                      details = 'Items: ${items.length}';
                    } else if (status == 'Canceled') {
                      details = data['cancellationReason'] ?? 'No reason provided';
                    } else if (status == 'Delivered') {
                      details = 'Delivered to: ${data['deliveryAddress']?['address'] ?? 'N/A'}';
                    } else if (status == 'Picked Up') { // Logic for 'Picked Up' status
                       details = 'Items: ${items.length} (Self-pickup)';
                    }
                    
                    return FutureBuilder<Map<String, String>>(
                      future: _fetchNames(userId, shopId),
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
                        final shopName = names['shopName'] ?? 'Unknown Shop';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ID: $orderId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text('Customer: $customerName'),
                                Text('Shop: $shopName'),
                                Text('Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(orderDate.toDate())}'),
                                Text('Status: $status', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                                Text('Details: $details'),
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

  Future<Map<String, String>> _fetchNames(String customerId, String shopId) async {
    final Map<String, String> names = {};
    
    if (customerId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      names['customerName'] = customerDoc.exists ? (customerDoc.data()?['name'] ?? 'N/A') : 'Unknown Customer';
    } else {
      names['customerName'] = 'Unknown Customer';
    }

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
      case 'Picked Up': // New case for 'Picked Up'
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}