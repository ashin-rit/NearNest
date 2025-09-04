import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:nearnest/screens/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              cart.clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared!'),
                ),
              );
            },
          ),
        ],
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final product = cart.items.values.toList()[index];
                      return ListTile(
                        leading: product.imageUrl.isNotEmpty
                            ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.shopping_bag),
                        title: Text(product.name),
                        subtitle: Text('Quantity: ${product.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${(product.price * product.quantity).toStringAsFixed(2)}'),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                cart.removeSingleItem(product.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed 1 ${product.name} from cart!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Total: ₹${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
