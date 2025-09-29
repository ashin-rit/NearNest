import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopOrderManagementScreen extends StatefulWidget {
  final String shopId;

  const ShopOrderManagementScreen({super.key, required this.shopId});

  @override
  State<ShopOrderManagementScreen> createState() =>
      _ShopOrderManagementScreenState();
}

class _ShopOrderManagementScreenState extends State<ShopOrderManagementScreen>
    with TickerProviderStateMixin {
  String _selectedStatus = 'All';
  bool _sortAscending = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();
  late AnimationController _fadeController;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Canceled',
    'Delivered',
    'Picked Up',
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
    _remarksController.dispose();
    _cancelReasonController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _openMap(
    double latitude,
    double longitude,
    String customerName,
  ) async {
    if (latitude == 0.0 || longitude == 0.0) {
      _showSnackBar('Customer location not available', Colors.orange);
      return;
    }

    // Try Google Maps URL scheme first (better for mobile)
    final googleMapsUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude',
    );

    // Fallback to web URL
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open map application', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error opening maps: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCustomerLocationDialog(
    BuildContext context,
    Map<String, dynamic> customerData,
  ) {
    final String customerName = customerData['name'] ?? 'Unknown Customer';
    final String streetAddress = customerData['streetAddress'] ?? '';
    final String city = customerData['city'] ?? '';
    final String state = customerData['state'] ?? '';
    final String pincode = customerData['pincode'] ?? '';
    final double latitude =
        (customerData['latitude'] as num?)?.toDouble() ?? 0.0;
    final double longitude =
        (customerData['longitude'] as num?)?.toDouble() ?? 0.0;
    final String phone = customerData['phone'] ?? '';

    final String fullAddress = [
      if (streetAddress.isNotEmpty) streetAddress,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ].where((s) => s.isNotEmpty).join(', ');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated header with gradient background
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.2),
                          Colors.cyan.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Customer Location',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enhanced address card with animation
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF8FAFC),
                          Colors.blue.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 8,
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.home_rounded,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Delivery Address',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullAddress.isEmpty
                                ? 'No address available'
                                : fullAddress,
                            style: TextStyle(
                              color: fullAddress.isEmpty
                                  ? Colors.red[400]
                                  : const Color(0xFF6B7280),
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (latitude != 0.0 && longitude != 0.0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.gps_fixed,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'GPS Coordinates Available',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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

                  // Contact info if available
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                phone,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons with enhanced styling
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B7280),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: latitude != 0.0 && longitude != 0.0
                              ? () {
                                  Navigator.of(context).pop();
                                  _openMap(latitude, longitude, customerName);
                                }
                              : null,
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Open in Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: latitude != 0.0 && longitude != 0.0
                                ? Colors.blue
                                : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: latitude != 0.0 && longitude != 0.0
                                ? 2
                                : 0,
                            shadowColor: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (latitude == 0.0 || longitude == 0.0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'GPS coordinates not available for this customer',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('shopId', isEqualTo: widget.shopId);

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    query = query.orderBy('orderDate', descending: _sortAscending);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: const Color(0xFF6366F1),
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
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeController,
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order =
                          orders[index].data() as Map<String, dynamic>;
                      final String orderId = orders[index].id;
                      return _buildOrderCard(order, orderId, index);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter by status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 16),
                  child: FilterChip(
                    label: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : _getStatusColor(status),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    backgroundColor: _getStatusColor(status).withOpacity(0.1),
                    selectedColor: _getStatusColor(status),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? _getStatusColor(status)
                          : _getStatusColor(status).withOpacity(0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    String orderId,
    int index,
  ) {
    final String status = order['status'] ?? 'Unknown';
    final String userId = order['userId'] ?? 'Unknown';
    final Timestamp orderDate = order['orderDate'];
    final List items = order['items'] ?? [];
    final bool isDelivery = order['isDelivery'] ?? false;
    final double totalAmount = (order['total'] as num?)?.toDouble() ?? 0.0;
    final String? remarks = order['remarks'];
    final String? cancelReason = order['cancelReason'];
    final String deliveryOption = isDelivery ? 'Delivery' : 'Pickup';

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchCustomerData(userId),
      builder: (context, customerSnapshot) {
        final customerData = customerSnapshot.data ?? {'name': 'Loading...'};
        final customerName = customerData['name'] ?? 'Unknown Customer';

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              if (status == 'Pending' || status == 'Confirmed') {
                _showOrderActionDialog(
                  context,
                  orderId,
                  status,
                  deliveryOption.toLowerCase(),
                  remarks,
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                    _buildOrderHeader(
                      orderId,
                      status,
                      orderDate,
                      deliveryOption,
                      customerData,
                      isDelivery,
                    ),
                    const SizedBox(height: 16),
                    _buildCustomerInfo(customerName),
                    if (remarks != null && remarks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoChip(
                        'Remarks',
                        remarks,
                        Icons.note_rounded,
                        Colors.blue,
                      ),
                    ],
                    if (cancelReason != null && cancelReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoChip(
                        'Cancellation Reason',
                        cancelReason,
                        Icons.cancel_rounded,
                        Colors.red,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _buildOrderItems(items),
                    const SizedBox(height: 16),
                    _buildTotalSection(totalAmount),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderHeader(
    String orderId,
    String status,
    Timestamp orderDate,
    String deliveryOption,
    Map<String, dynamic> customerData,
    bool isDelivery,
  ) {
    final bool hasLocation =
        customerData['latitude'] != null && customerData['longitude'] != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${orderId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
                    ).format(orderDate.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(status).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Interactive Delivery/Pickup badge
            GestureDetector(
              onTap: isDelivery && hasLocation
                  ? () => _showCustomerLocationDialog(context, customerData)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: isDelivery && hasLocation
                      ? LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.15),
                            Colors.cyan.withOpacity(0.1),
                          ],
                        )
                      : null,
                  color: isDelivery && hasLocation
                      ? null
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDelivery && hasLocation
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deliveryOption == 'Delivery'
                          ? Icons.local_shipping_rounded
                          : Icons.store_rounded,
                      size: 14,
                      color: isDelivery && hasLocation
                          ? Colors.blue[700]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deliveryOption,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDelivery && hasLocation
                            ? Colors.blue[700]
                            : Colors.grey[600],
                      ),
                    ),
                    if (isDelivery && hasLocation) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.blue[700],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(String customerName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF6366F1),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_bag_rounded,
              size: 16,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final String name = item['name'] ?? 'Unknown Item';
    final int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final String imageUrl = item['imageUrl'] ?? '';
    final double itemTotal = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.grey.shade200,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity × ₹${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${itemTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Text(
            '₹${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading orders...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Colors.grey.shade400,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Orders Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t received any orders yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
    String orderId,
    String newStatus, {
    String? remarks,
    String? cancelReason,
  }) async {
    try {
      final updateData = <String, dynamic>{'status': newStatus};
      if (remarks != null) {
        updateData['remarks'] = remarks;
      }
      if (cancelReason != null) {
        updateData['cancelReason'] = cancelReason;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showOrderActionDialog(
    BuildContext context,
    String orderId,
    String status,
    String deliveryOption,
    String? currentRemarks,
  ) {
    if (status == 'Pending') {
      _remarksController.text = currentRemarks ?? '';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Pending Order Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _remarksController,
                    decoration: InputDecoration(
                      labelText: 'Add remarks for customer',
                      hintText: 'Enter any special instructions...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _updateOrderStatus(
                        orderId,
                        'Confirmed',
                        remarks: _remarksController.text,
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Confirm Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCancelDialog(context, orderId);
                    },
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (status == 'Confirmed') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Confirmed Order Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (deliveryOption == 'delivery')
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'Delivered');
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.local_shipping_rounded),
                      label: const Text('Mark as Delivered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (deliveryOption == 'pickup')
                    ElevatedButton.icon(
                      onPressed: () {
                        _updateOrderStatus(orderId, 'Picked Up');
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.store_rounded),
                      label: const Text('Mark as Picked Up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    _cancelReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _cancelReasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for cancellation',
                    hintText: 'Please provide a reason...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_cancelReasonController.text.isNotEmpty) {
                      _updateOrderStatus(
                        orderId,
                        'Canceled',
                        cancelReason: _cancelReasonController.text,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Please enter a cancellation reason.',
                          ),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Confirm Cancellation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchCustomerData(String userId) async {
    if (userId.isNotEmpty) {
      try {
        final customerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (customerDoc.exists) {
          return customerDoc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        return {'name': 'Unknown Customer'};
      }
    }
    return {'name': 'Unknown Customer'};
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'All':
        return const Color(0xFF6B7280);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'Confirmed':
        return const Color(0xFF10B981);
      case 'Canceled':
        return const Color(0xFFEF4444);
      case 'Delivered':
        return const Color(0xFF3B82F6);
      case 'Picked Up':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
