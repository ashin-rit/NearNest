import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ShopOrderManagementScreen extends StatefulWidget {
  final String shopId;

  const ShopOrderManagementScreen({super.key, required this.shopId});

  @override
  State<ShopOrderManagementScreen> createState() =>
      _ShopOrderManagementScreenState();
}

class _ShopOrderManagementScreenState extends State<ShopOrderManagementScreen> {
  String _selectedStatus = 'All';
  bool _sortAscending = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
    'Delivered',
    'Picked Up',
  ];

  @override
  void dispose() {
    _remarksController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

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
                  return const Center(child: Text('No orders found.'));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final String orderId = orders[index].id;
                    final String status = order['status'] ?? 'Unknown';
                    final String userId = order['userId'] ?? 'Unknown';
                    final Timestamp orderDate = order['orderDate'];
                    final List items = order['items'] ?? []; // Changed from 'details' to 'items'
                    final bool isDelivery = order['isDelivery'] ?? false; // Using isDelivery field
                    final double totalAmount = (order['total'] as num?)?.toDouble() ?? 0.0; // Using total field from document
                    final String? remarks = order['remarks'];
                    final String? cancelReason = order['cancelReason'];

                    String deliveryOption = isDelivery ? 'delivery' : 'pickup';

                    return FutureBuilder<String>(
                      future: _fetchCustomerName(userId),
                      builder: (context, customerSnapshot) {
                        final customerName =
                            customerSnapshot.data ?? 'Fetching...';
                        return InkWell(
                          onTap: () {
                            if (status == 'Pending' || status == 'Confirmed') {
                              _showOrderActionDialog(context, orderId, status, deliveryOption, remarks);
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
                                    'Order ID: $orderId',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Customer: $customerName'),
                                  Text(
                                      'Time: ${DateFormat('yyyy-MM-dd – kk:mm').format(orderDate.toDate())}'),
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
                                  Text('Delivery Option: $deliveryOption'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Order Details:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey),
                                  ),
                                  const SizedBox(height: 8),
                                  // Display items with image, name, quantity, and price
                                  ...items.map<Widget>((item) {
                                    final String name = item['name'] ?? 'Unknown Item';
                                    final int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                                    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                                    final String imageUrl = item['imageUrl'] ?? '';
                                    final double itemTotal = price * quantity;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          // Product Image
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8.0),
                                              color: Colors.grey.withOpacity(0.2),
                                            ),
                                            child: imageUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8.0),
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return const Icon(
                                                          Icons.image_not_supported,
                                                          color: Colors.grey,
                                                          size: 24,
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                    size: 24,
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Product Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Qty: $quantity × ₹${price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  'Subtotal: ₹${itemTotal.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Amount:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '₹${totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
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

  Future<void> _updateOrderStatus(String orderId, String newStatus, {String? remarks, String? cancelReason}) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus};
      if (remarks != null) {
        updateData['remarks'] = remarks;
      }
      if (cancelReason != null) {
        updateData['cancelReason'] = cancelReason;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $e'),
        ),
      );
    }
  }

  void _showOrderActionDialog(
      BuildContext context, String orderId, String status, String deliveryOption, String? currentRemarks) {
    if (status == 'Pending') {
      _remarksController.text = currentRemarks ?? '';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pending Order Actions'),
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
                      _updateOrderStatus(orderId, 'Confirmed', remarks: _remarksController.text);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm Order'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCancelDialog(context, orderId);
                    },
                    child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
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
    } else if (status == 'Confirmed') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmed Order Actions'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  if (deliveryOption == 'delivery')
                    ElevatedButton(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'Delivered');
                        Navigator.of(context).pop();
                      },
                      child: const Text('Mark as Delivered'),
                    ),
                  if (deliveryOption == 'pickup')
                    ElevatedButton(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'Picked Up');
                        Navigator.of(context).pop();
                      },
                      child: const Text('Mark as Picked Up'),
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

  void _showCancelDialog(BuildContext context, String orderId) {
    _cancelReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
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
                  _updateOrderStatus(orderId, 'Canceled', cancelReason: _cancelReasonController.text);
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
      case 'Delivered':
        return Colors.blue;
      case 'Picked Up':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}