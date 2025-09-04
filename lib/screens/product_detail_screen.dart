import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/models/product_model.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) {
        _quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart_screen');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.product.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${widget.product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.product.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _decrementQuantity,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _incrementQuantity,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                onPressed: widget.product.isAvailable
                    ? () {
                        // Check for user login before adding to cart
                        if (FirebaseAuth.instance.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to add items to your cart.'),
                            ),
                          );
                          return;
                        }
                        
                        cart.addItem(widget.product, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$_quantity x ${widget.product.name} added to cart!'),
                          ),
                        );
                      }
                    : null,
              ),
              if (!widget.product.isAvailable)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
