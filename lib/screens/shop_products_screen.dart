// lib/screens/shop_products_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/widgets/product_list_item.dart';

class ShopProductsScreen extends StatelessWidget {
  final String shopId;
  final String shopName;

  const ShopProductsScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$shopName\'s Products'),
        backgroundColor: const Color(0xFF34D399),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('shopId', isEqualTo: shopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('This shop has no products yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final productDoc = snapshot.data!.docs[index];
              final data = productDoc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? 'N/A';
              final double price = data['price'] ?? 0.0;
              final String description = data['description'] ?? 'No description.';

              return ProductListItem(
                name: name,
                price: price,
                description: description,
              );
            },
          );
        },
      ),
    );
  }
}