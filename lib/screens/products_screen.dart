// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/models/product_model.dart';
import 'package:nearnest/services/shopping_cart_service.dart';

class ProductsScreen extends StatelessWidget {
  final String shopId;
  final String shopName;

  const ProductsScreen({super.key, required this.shopId, required this.shopName});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart_screen');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('shopId', isEqualTo: shopId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found for this shop.'));
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Product(
              id: doc.id,
              shopId: data['shopId'] ?? '',
              name: data['name'] ?? 'N/A',
              description: data['description'] ?? 'No description.',
              price: (data['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: data['imageUrl'] ?? '',
            );
          }).toList();

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                child: ListTile(
                  leading: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.shopping_bag,color: Colors.green),
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${product.price.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Text(product.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
                    onPressed: () {
                      cart.addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} added to cart!')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}