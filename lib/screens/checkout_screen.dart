// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore; // Alias the import
import 'package:nearnest/models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  String _selectedDeliveryOption = 'pickup';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context) async {
    final cart = Provider.of<ShoppingCartService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Cart is empty or user is not logged in.')),
      );
      return;
    }

    try {
      // For simplicity, we assume all products are from a single shop.
      final shopId = cart.items.values.first.shopId;
      final isDelivery = _selectedDeliveryOption == 'delivery';
      final orderRef = firestore.FirebaseFirestore.instance.collection('orders').doc(); // Use firestore.FirebaseFirestore

      final newOrder = Order(
        id: orderRef.id,
        userId: user.uid,
        shopId: shopId,
        items: cart.items.values.toList(),
        total: cart.total,
        isDelivery: isDelivery,
        deliveryAddress: isDelivery ? {'address': _addressController.text} : null,
        orderDate: firestore.Timestamp.now(), // Use firestore.Timestamp
        status: 'Pending',
      );

      await orderRef.set(newOrder.toMap());
      cart.clearCart();

      // Show success message and navigate back to the home screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context);

    // Assuming all items in the cart are from the same shop.
    final bool offersDelivery =
        (cart.items.isNotEmpty) ? (cart.items.values.first.toMap()['deliveryOption'] ?? false) : false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...cart.items.values.map((product) => ListTile(
                  leading: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.shopping_bag),
                  title: Text(product.name),
                  subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('₹${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            if (offersDelivery)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delivery Option', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Pickup from Store'),
                    value: 'pickup',
                    groupValue: _selectedDeliveryOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryOption = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Home Delivery'),
                    value: 'delivery',
                    groupValue: _selectedDeliveryOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryOption = value!;
                      });
                    },
                  ),
                  if (_selectedDeliveryOption == 'delivery')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _placeOrder(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Confirm Order', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}