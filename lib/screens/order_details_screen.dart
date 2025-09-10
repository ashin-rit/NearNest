import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color.fromARGB(255, 255, 235, 218),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          final totalAmount = order['totalAmount'] as double;
          final orderDate = order['orderDate'] as Timestamp;
          final status = order['status'] as String;
          final userId = order['userId'] as String;
          final deliveryType = order['deliveryType'] as String;
          final deliveryAddress = order['deliveryAddress'] as String? ?? 'N/A';
          final remarks = order['remarks'] as String? ?? 'None';
          final List<dynamic> items = order['items'] as List<dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard('Order ID', orderId),
                _buildDetailCard('Status', status, color: _getStatusColor(status)),
                _buildDetailCard('Date', DateFormat('yyyy-MM-dd – kk:mm').format(orderDate.toDate())),
                _buildDetailCard('Delivery Type', deliveryType),
                if (deliveryType == 'delivery') _buildDetailCard('Delivery Address', deliveryAddress),
                _buildDetailCard('Remarks', remarks),
                _buildDetailCard('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text(
                  'Ordered Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, color: color),
            ),
          ],
        ),
      ),
    );
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
