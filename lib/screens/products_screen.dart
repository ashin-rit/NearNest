import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:nearnest/models/product_model.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:nearnest/screens/product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ProductsScreen({super.key, required this.shopId, required this.shopName});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadCategories() async {
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    final Set<String> uniqueCategories = {};
    for (var doc in productsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String?;
      if (category != null && category.isNotEmpty) {
        uniqueCategories.add(category);
      }
    }
    setState(() {
      _categories = ['All', ...uniqueCategories.toList()..sort()];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<ShoppingCartService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart_screen');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'All');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = selected && category != 'All' ? category : null;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Product Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('shopId', isEqualTo: widget.shopId)
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

                final products = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Product(
                        id: doc.id,
                        shopId: data['shopId'] ?? '',
                        name: data['name'] ?? 'No Name',
                        description: data['description'] ?? 'No description.',
                        price: (data['price'] ?? 0.0).toDouble(),
                        isAvailable: data['isAvailable'] ?? true,
                        imageUrl: data['imageUrl'] ?? '',
                        category: data['category'] ?? 'Uncategorized',
                      );
                    })
                    .where((product) {
                      final matchesSearch = _searchQuery.isEmpty ||
                          product.name.toLowerCase().contains(_searchQuery);
                      final matchesCategory = _selectedCategory == null ||
                          product.category == _selectedCategory;
                      return matchesSearch && matchesCategory;
                    })
                    .toList();
                if (products.isEmpty) {
                  return const Center(child: Text('No products match your filters.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9, // This value is what controls the size of the tiles.
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            Expanded(
                              child: product.imageUrl.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(child: Icon(Icons.broken_image, size: 50)),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.shopping_bag, size: 50)),
                                    ),
                            ),
                            // Product Details
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  if (!product.isAvailable)
                                    const Text(
                                      'Out of Stock',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                            // Add to Cart Button
                            if (product.isAvailable)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
                                  onPressed: () {
                                    cart.addItem(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${product.name} added to cart!')),
                                    );
                                  },
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(Icons.add_shopping_cart, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
