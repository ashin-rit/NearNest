import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _showAddEditProductDialog([DocumentSnapshot? productDoc]) async {
    final isEditing = productDoc != null;
    final data = isEditing ? productDoc.data() as Map<String, dynamic> : {};
    final productNameController = TextEditingController(text: data['name'] ?? '');
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final categoryController = TextEditingController(text: data['category'] ?? '');
    final imageUrlController = TextEditingController(text: data['imageUrl'] ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: productNameController,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                        validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Price cannot be empty' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'Category'),
                        validator: (value) => value!.isEmpty ? 'Category cannot be empty' : null,
                      ),
                      TextFormField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(labelText: 'Image URL'),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: imageUrlController.text.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.red)),
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Enter an image URL'),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final userId = _auth.currentUser!.uid;

                      final productData = {
                        'name': productNameController.text.trim(),
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'description': descriptionController.text.trim(),
                        'category': categoryController.text.trim(),
                        'imageUrl': imageUrlController.text.trim(),
                        'shopId': userId,
                        'isAvailable': isEditing ? data['isAvailable'] : true,
                        'createdAt': isEditing ? data['createdAt'] : FieldValue.serverTimestamp(),
                        'lastUpdated': FieldValue.serverTimestamp(),
                      };

                      try {
                        if (isEditing) {
                          await _firestore.collection('products').doc(productDoc.id).update(productData);
                        } else {
                          await _firestore.collection('products').add(productData);
                        }
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Product ${isEditing ? 'updated' : 'added'} successfully!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to ${isEditing ? 'update' : 'add'} product: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('products').doc(productId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: $e')),
        );
      }
    }
  }

  Future<void> _toggleAvailability(String productId, bool isAvailable) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isAvailable': !isAvailable,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product is now ${!isAvailable ? 'available' : 'unavailable'}.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product availability: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('You must be logged in to manage products.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('shopId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no products yet.'));
          }

          final categories =
              snapshot.data!.docs.map((doc) => (doc.data() as Map<String, dynamic>)['category']?.toString() ?? 'Other')
                  .toSet().toList();
          categories.sort();

          final filteredProducts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name']?.toString().toLowerCase() ?? '';
            final category = data['category']?.toString() ?? '';
            final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
            final matchesCategory = _selectedCategory == null || category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search Products',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Text('Category'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All'),
                        ),
                        ...categories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(child: Text('No products match your search/filter.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final productDoc = filteredProducts[index];
                          final data = productDoc.data() as Map<String, dynamic>;
                          final bool isAvailable = data['isAvailable'] ?? true;
                          final String imageUrl = data['imageUrl'] ?? '';

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                                              )
                                            : const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['name'] ?? 'No Name',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${data['price']?.toString() ?? '0.00'}',
                                            style: const TextStyle(color: Colors.green, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: IconButton(
                                    icon: Icon(
                                      isAvailable ? Icons.visibility : Icons.visibility_off,
                                      color: isAvailable ? Colors.green : Colors.grey,
                                    ),
                                    onPressed: () => _toggleAvailability(productDoc.id, isAvailable),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                        onPressed: () => _showAddEditProductDialog(productDoc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteProduct(productDoc.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditProductDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}