// lib/screens/shop_service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:nearnest/services/favorites_service.dart';

class ShopServiceDetailScreen extends StatefulWidget {
  final String itemId; // <-- New parameter to accept the document ID
  final Map<String, dynamic> data;

  const ShopServiceDetailScreen({super.key, required this.itemId, required this.data});

  @override
  State<ShopServiceDetailScreen> createState() => _ShopServiceDetailScreenState();
}

class _ShopServiceDetailScreenState extends State<ShopServiceDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    // Use widget.itemId to check the favorite status
    final bool isFavorite = await _favoritesService.isFavorite(widget.itemId);
    if (mounted) {
      setState(() {
        _isFavorited = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorited) {
      // Use widget.itemId to remove from favorites
      await _favoritesService.removeFavorite(widget.itemId);
    } else {
      // Use widget.itemId and widget.data['role'] to add to favorites
      await _favoritesService.addFavorite(widget.itemId, widget.data['role']!);
    }
    setState(() {
      _isFavorited = !_isFavorited;
    });
  }

  @override
  Widget build(BuildContext context) {    final String name = widget.data['name'] ?? 'N/A';
    final String role = widget.data['role'] ?? 'N/A';
    final String description = widget.data['description'] ?? 'No description provided.';
    final String phone = widget.data['phone'] ?? 'N/A';
    final String address = widget.data['address'] ?? 'No address provided.';
    final String category = widget.data['category'] ?? 'N/A';
    final String imageUrl = widget.data['imageUrl'] ?? 'https://via.placeholder.com/300';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorited ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(blurRadius: 5.0, color: Colors.black, offset: Offset(2, 2)),
                  ],
                ),
              ),
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey,
                  child: Center(
                    child: Icon(
                      role == 'Shop' ? Icons.store : Icons.business_center,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard(
                    title: 'Category',
                    value: category,
                    icon: Icons.category,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    title: 'Contact',
                    value: phone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    title: 'Address',
                    value: address,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF065F46)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}