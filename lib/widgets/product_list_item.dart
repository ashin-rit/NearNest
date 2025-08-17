// lib/widgets/product_list_item.dart
import 'package:flutter/material.dart';

class ProductListItem extends StatelessWidget {
  final String name;
  final double price;
  final String description;

  const ProductListItem({
    super.key,
    required this.name,
    required this.price,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: Color(0xFF34D399), size: 40),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Price: \$${price.toStringAsFixed(2)}\n$description'),
        isThreeLine: true,
      ),
    );
  }
}