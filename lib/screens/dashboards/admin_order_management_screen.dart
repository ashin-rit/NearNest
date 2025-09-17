import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen>
    with TickerProviderStateMixin {
  String _selectedStatus = 'All';
  bool _sortAscending = false;
  late AnimationController _fadeController;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'All', 'color': Color(0xFF6B7280), 'icon': Icons.all_inclusive_rounded},
    {'value': 'Pending', 'color': Color(0xFFF59E0B), 'icon': Icons.schedule_rounded},
    {'value': 'Confirmed', 'color': Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
    {'value': 'Canceled', 'color': Color(0xFFEF4444), 'icon': Icons.cancel_rounded},
    {'value': 'Delivered', 'color': Color(0xFF3B82F6), 'icon': Icons.local_shipping_rounded},
    {'value': 'Picked Up', 'color': Color(0xFF8B5CF6), 'icon': Icons.inventory_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchNames(String customerId, String shopId) async {
    final Map<String, String> names = {};
    
    if (customerId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      names['customerName'] = customerDoc.exists
          ? (Map<String, dynamic>.from(customerDoc.data() as Map)['name'] ?? 'N/A')
          : 'Unknown Customer';
    } else {
      names['customerName'] = 'Unknown Customer';
    }

    if (shopId.isNotEmpty) {
      final shopDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(shopId)
          .get();
      names['shopName'] = shopDoc.exists
          ? (Map<String, dynamic>.from(shopDoc.data() as Map)['name'] ?? 'N/A')
          : 'Unknown Shop';
    } else {
      names['shopName'] = 'Unknown Shop';
    }

    return names;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF10B981);
      case 'Canceled':
        return const Color(0xFFEF4444);
      case 'Delivered':
        return const Color(0xFF3B82F6);
      case 'Picked Up':
        return const Color(0xFF8B5CF6);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Confirmed':
        return Icons.check_circle_rounded;
      case 'Canceled':
        return Icons.cancel_rounded;
      case 'Delivered':
        return Icons.local_shipping_rounded;
      case 'Picked Up':
        return Icons.inventory_rounded;
      case 'Pending':
        return Icons.schedule_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('orders');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            // Status Filter Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusOptions.map((option) {
                        final isSelected = _selectedStatus == option['value'];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedStatus = option['value'];
                                });
                              },
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? option['color']
                                      : option['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: option['color'],
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      option['icon'],
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : option['color'],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      option['value'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : option['color'],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Orders List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final status = Map<String, dynamic>.from(doc.data() as Map);
                    if (_selectedStatus == 'All') {
                      return true;
                    }
                    return status['status'] == _selectedStatus;
                  }).toList();

                  filteredDocs.sort((a, b) {
                    final aTimestamp = (Map<String, dynamic>.from(a.data() as Map))['orderDate'] as Timestamp? ?? Timestamp.now();
                    final bTimestamp = (Map<String, dynamic>.from(b.data() as Map))['orderDate'] as Timestamp? ?? Timestamp.now();
                    
                    if (_sortAscending) {
                      return aTimestamp.compareTo(bTimestamp);
                    } else {
                      return bTimestamp.compareTo(aTimestamp);
                    }
                  });

                  if (filteredDocs.isEmpty) {
                    return _buildEmptyState(customMessage: 'No $_selectedStatus orders found');
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final orderDoc = filteredDocs[index];
                      final order = Map<String, dynamic>.from(orderDoc.data() as Map);
                      return _buildOrderCard(orderDoc.id, order, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String? customMessage}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            customMessage ?? 'No orders found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customMessage == null
                ? 'No orders available at the moment'
                : 'Try adjusting your filter',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order, int index) {
    final String customerId = order['userId'] ?? '';
    final String shopId = order['shopId'] ?? '';
    final double totalAmount = (order['total'] as num?)?.toDouble() ?? 0.0;
    final String status = order['status'] ?? 'N/A';
    final Timestamp orderTimestamp = order['orderDate'] ?? Timestamp.now();
    final String remarks = order['remarks'] ?? '';
    final String cancelReason = order['cancellationReason'] ?? '';
    final List<dynamic> items = order['items'] ?? [];

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${orderId.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Order Details with FutureBuilder
                    FutureBuilder<Map<String, String>>(
                      future: _fetchNames(customerId, shopId),
                      builder: (context, namesSnapshot) {
                        if (!namesSnapshot.hasData) {
                          return Container(
                            height: 40,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          );
                        }
                        
                        final names = namesSnapshot.data!;
                        final customerName = names['customerName'] ?? 'Unknown Customer';
                        final shopName = names['shopName'] ?? 'Unknown Shop';

                        return Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.person_rounded,
                              label: 'Customer',
                              value: customerName,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.storefront_rounded,
                              label: 'Shop',
                              value: shopName,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.access_time_rounded,
                              label: 'Order Time',
                              value: DateFormat('MMM dd, yyyy • hh:mm a')
                                  .format(orderTimestamp.toDate()),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // Products
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Products',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...items.take(3).map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${item['name']} × ${item['quantity']}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            )),
                            if (items.length > 3)
                              Text(
                                '... and ${items.length - 3} more items',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Additional Info
                    if (status == 'Confirmed' && remarks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remarks',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remarks,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (status == 'Canceled' && cancelReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cancellation Reason',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cancelReason,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }
}