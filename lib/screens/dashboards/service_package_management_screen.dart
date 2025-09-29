// lib/screens/dashboards/service_package_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServicePackageManagementScreen extends StatefulWidget {
  const ServicePackageManagementScreen({super.key});

  @override
  State<ServicePackageManagementScreen> createState() =>
      _ServicePackageManagementScreenState();
}

class _ServicePackageManagementScreenState
    extends State<ServicePackageManagementScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  String get currentUserId => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showPackageDialog({DocumentSnapshot? doc}) async {
    final TextEditingController nameController =
        TextEditingController(text: doc?['name'] ?? '');
    final TextEditingController descriptionController =
        TextEditingController(text: doc?['description'] ?? '');
    final TextEditingController priceController =
        TextEditingController(text: doc?['price']?.toString() ?? '');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Color(0xFF0EA5E9),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  doc == null ? 'Add Service Package' : 'Edit Service Package',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: nameController,
                  label: 'Service Name',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: priceController,
                  label: 'Price',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final String name = nameController.text;
                          final String description = descriptionController.text;
                          final double price = double.tryParse(priceController.text) ?? 0.0;

                          if (name.isNotEmpty && price > 0) {
                            try {
                              if (doc == null) {
                                await _firestore.collection('service_packages').add({
                                  'name': name,
                                  'description': description,
                                  'price': price,
                                  'serviceProviderId': currentUserId,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                if (mounted) {
                                  _showSnackBar('Package added successfully!', Colors.green);
                                }
                              } else {
                                await _firestore.collection('service_packages').doc(doc.id).update({
                                  'name': name,
                                  'description': description,
                                  'price': price,
                                });
                                if (mounted) {
                                  _showSnackBar('Package updated successfully!', Colors.blue);
                                }
                              }
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar('Failed to save package: $e', Colors.red);
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFF9FAFB),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _deletePackage(String packageId) async {
    try {
      await _firestore.collection('service_packages').doc(packageId).delete();
      if (mounted) {
        _showSnackBar('Package deleted successfully!', Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to delete package: $e', Colors.red);
      }
    }
  }

  Future<void> _showDeleteConfirmation(String packageId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Service Package?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to delete this service package? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirm == true) {
      _deletePackage(packageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Service Packages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0EA5E9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('service_packages')
            .where('serviceProviderId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      size: 60,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No service packages yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first service package to get started',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final packages = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final doc = packages[index];
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business_center,
                              color: Color(0xFF0EA5E9),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\₹${(data['price'] ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: () => _showPackageDialog(doc: doc),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _showDeleteConfirmation(doc.id),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data['description'] ?? 'N/A',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showPackageDialog(),
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          elevation: 8,
          icon: const Icon(Icons.add),
          label: const Text(
            'Add Package',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}