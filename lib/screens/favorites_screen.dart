// lib/screens/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/screens/shop_service_detail_screen.dart';
import 'package:nearnest/services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _favoritesService.getFavoriteItemIds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final favoriteIds = snapshot.data ?? [];
        if (favoriteIds.isEmpty) {
          return const Center(
            child: Text(
              'You have no favorite shops or services yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: favoriteIds.length,
          itemBuilder: (context, index) {
            final itemId = favoriteIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(itemId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                    leading: CircularProgressIndicator(),
                  );
                }
                if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink(); // Hide if data is not found
                }

                final data = userSnapshot.data!.data() as Map<String, dynamic>;
                final String name = data['name'] ?? 'N/A';
                final String role = data['role'] ?? 'N/A';
                final String imageUrl = data['imageUrl'] ?? '';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50)),
                          )
                        : Icon(
                            role == 'Shop' ? Icons.store : Icons.business_center,
                            size: 50,
                            color: Theme.of(context).primaryColor,
                          ),
                    title: Text(name),
                    subtitle: Text(role),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () async {
                        await _favoritesService.removeFavorite(itemId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name removed from favorites.')),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopServiceDetailScreen(itemId: itemId, data: data),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}