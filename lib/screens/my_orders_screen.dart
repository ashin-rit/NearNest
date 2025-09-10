import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  /// Fetches the shop's name using its shopId.
  Future<String> _fetchShopName(String shopId) async {
    try {
      final shopDoc = await FirebaseFirestore.instance.collection('users').doc(shopId).get();
      if (shopDoc.exists) {
        return shopDoc.data()?['name'] ?? 'Unknown Shop';
      }
      return 'Unknown Shop';
    } catch (e) {
      print('Error fetching shop name: $e');
      return 'Unknown Shop';
    }
  }

  /// Determines the color of the status text based on the order's status.
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view your orders.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('You have no orders yet.'));
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderDoc = orders[index];
                  final order = orderDoc.data() as Map<String, dynamic>;
                  final String status = order['status'] ?? 'N/A';
                  final bool isDelivery = order['isDelivery'] ?? false;
                  final List<dynamic> items = order['items'] ?? [];
                  final String shopId = order['shopId'] ?? '';
                  final Timestamp? orderTimestamp = order['orderDate'];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: _fetchShopName(shopId),
                            builder: (context, shopNameSnapshot) {
                              if (shopNameSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading shop...');
                              }
                              return Text(
                                shopNameSnapshot.data ?? 'Unknown Shop',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (orderTimestamp != null) ...[
                            Text(
                              'Date: ${DateFormat('MMM d, yyyy').format(orderTimestamp.toDate())}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                  
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${DateFormat('h:mm a').format(orderTimestamp.toDate())}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text('Status: $status', style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
                          Text('Type: ${isDelivery ? 'Delivery' : 'Pickup'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...items.map((item) {
                            final double itemPrice = (item['price'] as num? ?? 0.0).toDouble();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  if (item['imageUrl'] != null && item['imageUrl']!.isNotEmpty)
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.image_not_supported, size: 50);
                                        },
                                      ),
                                    )
                                  else
                                    const Icon(Icons.shopping_bag_outlined, size: 50),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Quantity: ${item['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Price: ₹${itemPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
