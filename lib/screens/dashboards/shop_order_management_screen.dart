// lib/screens/dashboards/shop_order_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShopOrderManagementScreen extends StatefulWidget {
  final String shopId;

  const ShopOrderManagementScreen({super.key, required this.shopId});

  @override
  State<ShopOrderManagementScreen> createState() => _ShopOrderManagementScreenState();
}

class _ShopOrderManagementScreenState extends State<ShopOrderManagementScreen> {
  String _selectedStatus = 'All';
  bool _sortAscending = true;

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
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('shopId', isEqualTo: widget.shopId);

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    query = query.orderBy('orderDate', descending: _sortAscending);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color.fromARGB(255, 227, 255, 16),
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

                    final String userId = data['userId'] ?? '';
                    final Timestamp orderDate = data['orderDate'] as Timestamp? ?? Timestamp.now();
                    final String status = data['status'] ?? 'Pending';
                    final String orderId = doc.id;

                    String details = 'N/A';
                    final List<dynamic> items = data['items'] ?? [];
                    
                    if (status == 'Confirmed') {
                      details = 'Items: ${items.length}';
                    } else if (status == 'Canceled') {
                      details = data['cancellationReason'] ?? 'No reason provided';
                    } else if (status == 'Delivered') {
                      final deliveryAddress = data['deliveryAddress'] as Map<String, dynamic>?;
                      details = 'Delivered to: ${deliveryAddress?['address'] ?? 'N/A'}';
                    } else if (status == 'Picked Up') {
                       details = 'Items: ${items.length} (Self-pickup)';
                    }
                    
                    return FutureBuilder<String>(
                      future: _fetchCustomerName(userId),
                      builder: (context, nameSnapshot) {
                        if (nameSnapshot.connectionState == ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading user details...'),
                          );
                        }
                        if (nameSnapshot.hasError) {
                          return ListTile(
                            title: Text('Error loading name: ${nameSnapshot.error}'),
                            subtitle: const Text('User ID is invalid.'),
                          );
                        }

                        final customerName = nameSnapshot.data ?? 'Unknown Customer';

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
      case 'Delivered':
        return Colors.blue;
      case 'Picked Up':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}