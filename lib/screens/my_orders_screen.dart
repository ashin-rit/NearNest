import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

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
          const Text(
            'My Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
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
                  final double total = (order['totalAmount'] as num? ?? 0.0).toDouble();
                  final bool isDelivery = order['isDelivery'] ?? false;
                  final List<dynamic> items = order['items'] ?? [];
                  
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      title: Text('Order ID: ${orderDoc.id}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: $status'),
                          Text('Total: ₹${total.toStringAsFixed(2)}'),
                          Text(isDelivery ? 'Type: Delivery' : 'Type: Pickup'),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDelivery)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Address: ${order['deliveryAddress']['address'] ?? 'N/A'}'),
                                    const SizedBox(height: 5),
                                    Text('Remark: ${order['deliveryAddress']['remark'] ?? 'N/A'}'),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((item) {
                                final double itemPrice = (item['price'] as num? ?? 0.0).toDouble();
                                return Text(' - ${item['name']} (x${item['quantity']}) - ₹${itemPrice.toStringAsFixed(2)}');
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
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