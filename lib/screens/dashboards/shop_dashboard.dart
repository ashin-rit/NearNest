// lib/screens/dashboards/shop_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/dashboards/shop_profile_edit_screen.dart';
import 'package:nearnest/screens/product_management_screen.dart';
import 'package:nearnest/screens/login_page.dart';

class ShopDashboard extends StatefulWidget {
  const ShopDashboard({super.key});

  @override
  State<ShopDashboard> createState() => _ShopDashboardState();
}

class _ShopDashboardState extends State<ShopDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  DocumentSnapshot? _shopData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  Future<void> _fetchShopData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final shopData = await _authService.getUserDataByUid(user.uid);
        setState(() {
          _shopData = shopData;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load shop data.')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_shopData == null || !_shopData!.exists) {
      return const Scaffold(body: Center(child: Text('Shop data not found.')));
    }

    final data = _shopData!.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'N/A';
    final String role = data['role'] ?? 'N/A';
    final String email = data['email'] ?? 'N/A';
    final String phone = data['phone'] ?? 'N/A';
    final String address = data['address'] ?? 'N/A';
    final String description =
        data['description'] ?? 'No description provided.';
    final String category = data['category'] ?? 'N/A';
    final String business_hours = data['business_hours'] ?? 'N/A';
    final bool isDeliveryAvailable = data['isDeliveryAvailable'] ?? false;
    final String? uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('$name Dashboard'),
        backgroundColor: const Color(0xFFFACC15),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Shop Owner!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This is your business dashboard.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              title: 'Business Details',
              children: [
                _buildInfoRow(Icons.store, 'Name', name),
                _buildInfoRow(Icons.business_center, 'Role', role),
                _buildInfoRow(Icons.category, 'Category', category),
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  description,
                  isMultiLine: true,
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'Business Hours',
                  business_hours,
                ),
                _buildInfoRow(
                  Icons.delivery_dining,
                  'Delivery Available',
                  isDeliveryAvailable ? 'Yes' : 'No',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Contact Information',
              children: [
                _buildInfoRow(Icons.email, 'Email', email),
                _buildInfoRow(Icons.phone, 'Phone', phone),
                _buildInfoRow(
                  Icons.location_on,
                  'Address',
                  address,
                  isMultiLine: true,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => ShopProfileEditScreen(
                                userId: _auth.currentUser!.uid,
                                initialData: {
                                  ..._shopData!.data() as Map<String, dynamic>,
                                  'isDeliveryAvailable': isDeliveryAvailable,
                                },
                              ),
                            ),
                          )
                          .then((_) {
                            _fetchShopData();
                          });
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Business Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProductManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Manage Products',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAB308),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Incoming Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (uid != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('shopId', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No new orders.'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final orderDoc = snapshot.data!.docs[index];
                      final order = orderDoc.data() as Map<String, dynamic>;
                      final String status = order['status'] ?? 'N/A';
                      final double total = (order['total'] as num).toDouble();
                      final bool isDelivery = order['isDelivery'] ?? false;
                      final List<dynamic> items = order['items'] ?? [];

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                          title: Text('Order ID: ${orderDoc.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: $status'),
                              Text('Total: ₹${total.toStringAsFixed(2)}'),
                              Text(
                                isDelivery ? 'Type: Delivery' : 'Type: Pickup',
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isDelivery)
                                    Text(
                                      'Address: ${order['deliveryAddress']['address'] ?? 'N/A'}',
                                    ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...items
                                      .map(
                                        (item) => Text(
                                          ' - ${item['name']} (₹${(item['price'] as num).toDouble().toStringAsFixed(2)})',
                                        ),
                                      )
                                      .toList(),
                                  const SizedBox(height: 10),
                                  // You can add buttons here to update the order status
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: Implement logic to update order status to 'Shipped' or 'Completed'
                                    },
                                    child: const Text('Mark as Completed'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(color: Colors.grey, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: isMultiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
