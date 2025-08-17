// lib/screens/shop_service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/shop_products_screen.dart'; // Import the new screen
import 'package:nearnest/services/favorites_service.dart';

class ShopServiceDetailScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const ShopServiceDetailScreen({
    super.key,
    required this.itemId,
    required this.data,
  });

  @override
  State<ShopServiceDetailScreen> createState() => _ShopServiceDetailScreenState();
}

class _ShopServiceDetailScreenState extends State<ShopServiceDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await _favoritesService.isFavorite(widget.itemId);
    setState(() {
      _isFavorite = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String role = widget.data['role'] ?? 'N/A';
    final String name = widget.data['name'] ?? 'N/A';
    final String description = widget.data['description'] ?? 'No description provided.';
    final String imageUrl = widget.data['imageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 250,
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                child: Center(
                  child: Icon(
                    role == 'Shop' ? Icons.store : Icons.business_center,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 30,
                        ),
                        onPressed: () async {
                          if (_isFavorite) {
                            await _favoritesService.removeFavorite(widget.itemId);
                          } else {
                            await _favoritesService.addFavorite(widget.itemId, widget.data['role']!);
                          }
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isFavorite ? 'Added to favorites.' : 'Removed from favorites.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role: $role',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  if (role == 'Shop')
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShopProductsScreen(
                                shopId: widget.itemId,
                                shopName: name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        label: const Text('View Products', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAB308),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}