import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:nearnest/models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/cart_item_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _remarksController = TextEditingController();
  String _selectedDeliveryOption = 'pickup';
  bool _isDeliveryAvailable = false;
  bool _isCheckingDelivery = true;
  String _shopId = '';
  Map<String, dynamic>? _deliveryAddressData;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<ShoppingCartService>(context, listen: false);
    if (cart.items.isNotEmpty) {
      _shopId = cart.items.values.first.shopId;
      _fetchShopDeliveryStatus();
      _fetchUserAddress();
    } else {
      _isCheckingDelivery = false;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopDeliveryStatus() async {
    final shopDoc = await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(_shopId)
        .get();
    if (shopDoc.exists) {
      final data = shopDoc.data();
      setState(() {
        _isDeliveryAvailable = data?['delivery_enabled'] ?? false;
        _isCheckingDelivery = false;
        // If delivery is not available, default to pickup
        if (!_isDeliveryAvailable) {
          _selectedDeliveryOption = 'pickup';
        }
      });
    }
  }

  Future<void> _fetchUserAddress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('address')) {
          setState(() {
            _deliveryAddressData = data['address'];
          });
        }
      }
    }
  }

  String get formattedAddress {
    if (_deliveryAddressData == null) return 'No address found.';
    final street = _deliveryAddressData!['street'] ?? '';
    final city = _deliveryAddressData!['city'] ?? '';
    final state = _deliveryAddressData!['state'] ?? '';
    final zipCode = _deliveryAddressData!['zipCode'] ?? '';
    return '$street, $city, $state - $zipCode';
  }

  Future<void> _placeOrder(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }
    
    // Get the cart service instance
    final cart = Provider.of<ShoppingCartService>(context, listen: false);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }
    
    // Generate a unique ID for the new order
    final orderId = firestore.FirebaseFirestore.instance.collection('orders').doc().id;

    // Create an Order object with all required parameters and correct types
    final order = Order(
      id: orderId,
      total: cart.totalAmount,
      isDelivery: _selectedDeliveryOption == 'delivery',
      orderDate: firestore.Timestamp.fromDate(DateTime.now()),
      userId: userId,
      shopId: _shopId,
      items: cart.items.values.toList(),
      remarks: _remarksController.text,
      status: 'pending',
      deliveryAddress: _selectedDeliveryOption == 'delivery' ? _deliveryAddressData : null,
    );

    try {
      // Use the generated ID to set the new document
      await firestore.FirebaseFirestore.instance.collection('orders').doc(orderId).set(order.toMap());
      
      // Clear the cart in Firestore after the order is placed
      await cart.clearCart();

      // Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      Navigator.of(context).popUntil(ModalRoute.withName('/home_screen'));
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isCheckingDelivery
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'pickup',
                          groupValue: _selectedDeliveryOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedDeliveryOption = value!;
                            });
                          },
                        ),
                        const Text('Store Pickup'),
                      ],
                    ),
                    if (_isDeliveryAvailable)
                      Row(
                        children: [
                          Radio<String>(
                            value: 'delivery',
                            groupValue: _selectedDeliveryOption,
                            onChanged: (value) {
                              setState(() {
                                _selectedDeliveryOption = value!;
                              });
                            },
                          ),
                          const Text('Home Delivery'),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (_selectedDeliveryOption == 'delivery')
                      Text(
                        'Delivery Address: $formattedAddress',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Special Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
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
      ),
    );
  }
}
