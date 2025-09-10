import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:nearnest/models/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/cart_item_model.dart';
import 'package:nearnest/models/product_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();
  String _selectedDeliveryOption = 'delivery';
  bool _isDeliveryAvailable = false;
  String _shopId = '';
  String? _streetAddress;
  String? _city;
  String? _state;
  String? _pincode;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<ShoppingCartService>(context, listen: false);
    if (cart.items.isNotEmpty) {
      _shopId = cart.items.values.first.shopId;
      _fetchShopDeliveryStatus();
      _fetchUserAddress();
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopDeliveryStatus() async {
    try {
      // Fix: Correctly access the shop data from the 'users' collection
      final shopDoc = await FirebaseFirestore.instance.collection('users').doc(_shopId).get();
      if (shopDoc.exists) {
        final data = shopDoc.data();
        if (data != null && data['isDeliveryAvailable'] != null) {
          setState(() {
            _isDeliveryAvailable = data['isDeliveryAvailable'];
            // If delivery is not available, default to pickup
            if (!_isDeliveryAvailable) {
              _selectedDeliveryOption = 'pickup';
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching shop delivery status: $e');
    }
  }

  Future<void> _fetchUserAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _streetAddress = data?['streetAddress'] as String?;
          _city = data?['city'] as String?;
          _state = data?['state'] as String?;
          _pincode = data?['pincode'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching user address: $e');
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final cart = Provider.of<ShoppingCartService>(context, listen: false);

    if (user == null || cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot place an empty order. Please add items to your cart.')),
      );
      return;
    }

    try {
      final isDelivery = _selectedDeliveryOption == 'delivery';
      final orderData = Order(
        id: '', // Firestore will provide this
        userId: user.uid,
        items: cart.items.values.toList(),
        total: cart.totalAmount,
        isDelivery: isDelivery,
        shopId: _shopId,
        remarks: _remarksController.text,
        orderDate: Timestamp.now(),
        status: 'Pending',
      );
      
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      await ordersRef.add(orderData.toMap());

      await cart.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      // Fix: Use pop() to safely return to the previous screen.
      // This prevents the white screen that occurs when the route is not found.
      Navigator.pop(context);
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context);
    final totalAmount = cart.totalAmount;
    final formattedAddress = _streetAddress != null && _city != null && _state != null && _pincode != null
        ? '$_streetAddress, $_city, $_state, $_pincode'
        : 'Address not found. Please update your profile.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...cart.items.values.map((item) {
                    return ListTile(
                      leading: item.imageUrl.isNotEmpty
                          ? Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.shopping_bag),
                      title: Text(item.name),
                      subtitle: Text('Quantity: ${item.quantity}'),
                      trailing: Text('₹${(item.price * item.quantity).toStringAsFixed(2)}'),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      'Total Amount',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Delivery Options',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Pickup'),
                    value: 'pickup',
                    groupValue: _selectedDeliveryOption,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryOption = value!;
                      });
                    },
                  ),
                  if (_isDeliveryAvailable)
                    RadioListTile<String>(
                      title: const Text('Delivery'),
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
                      child: Text(
                        'Delivery Address: $formattedAddress',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Special Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
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
