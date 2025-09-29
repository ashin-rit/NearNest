import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() =>
      _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState
    extends State<AdminBookingManagementScreen>
    with TickerProviderStateMixin {
  String _selectedStatus = 'All';
  bool _sortAscending = false;
  late AnimationController _fadeController;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'value': 'All',
      'color': Color(0xFF6B7280),
      'icon': Icons.all_inclusive_rounded,
    },
    {
      'value': 'Pending',
      'color': Color(0xFFF59E0B),
      'icon': Icons.schedule_rounded,
    },
    {
      'value': 'Confirmed',
      'color': Color(0xFF10B981),
      'icon': Icons.check_circle_rounded,
    },
    {
      'value': 'Completed',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.task_alt_rounded,
    },
    {
      'value': 'Canceled',
      'color': Color(0xFFEF4444),
      'icon': Icons.cancel_rounded,
    },
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

  Stream<List<Map<String, dynamic>>> _fetchBookingsWithDetails() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'bookings',
    );

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final List<Map<String, dynamic>> detailedBookings = [];
      for (var bookingDoc in snapshot.docs) {
        final bookingData = Map<String, dynamic>.from(bookingDoc.data());
        final String customerId = bookingData['userId'] ?? '';
        final String serviceProviderId = bookingData['serviceProviderId'] ?? '';

        String customerName = 'Unknown Customer';
        String serviceProviderName = 'Unknown Provider';
        String serviceProviderCategory = 'N/A';

        if (customerId.isNotEmpty) {
          final customerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(customerId)
              .get();
          if (customerDoc.exists) {
            final customerData = Map<String, dynamic>.from(
              customerDoc.data() as Map,
            );
            customerName = customerData['name'] ?? 'N/A';
          }
        }

        if (serviceProviderId.isNotEmpty) {
          final providerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(serviceProviderId)
              .get();
          if (providerDoc.exists) {
            final providerData = Map<String, dynamic>.from(
              providerDoc.data() as Map,
            );
            serviceProviderName = providerData['name'] ?? 'N/A';
            serviceProviderCategory = providerData['category'] ?? 'N/A';
          }
        }

        detailedBookings.add({
          'id': bookingDoc.id,
          ...bookingData,
          'customerName': customerName,
          'serviceProviderName': serviceProviderName,
          'serviceProviderCategory': serviceProviderCategory,
        });
      }

      // Sort bookings
      detailedBookings.sort((a, b) {
        final aTime = a['bookingTime'] as Timestamp?;
        final bTime = b['bookingTime'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return _sortAscending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
      });

      return detailedBookings;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF10B981);
      case 'Completed':
        return const Color(0xFF8B5CF6);
      case 'Canceled':
        return const Color(0xFFEF4444);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Booking Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            // Bookings List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchBookingsWithDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final detailedBookings = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: detailedBookings.length,
                    itemBuilder: (context, index) {
                      final booking = detailedBookings[index];
                      return _buildBookingCard(booking, index);
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

  Widget _buildEmptyState() {
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
              Icons.calendar_today_rounded,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus == 'All'
                ? 'No bookings available at the moment'
                : 'No $_selectedStatus bookings found',
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
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
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, int index) {
    final String bookingId = booking['id'];
    final String? serviceName = booking['serviceName'];
    final double? servicePrice = (booking['servicePrice'] as num?)?.toDouble();
    final String? status = booking['status'];
    final String? remarks = booking['remarks'];
    final String? cancelReason = booking['cancellationReason'];
    final Timestamp? bookingTime = booking['bookingTime'];
    final String customerName = booking['customerName'];
    final String serviceProviderName = booking['serviceProviderName'];
    final String serviceProviderCategory = booking['serviceProviderCategory'];

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
                            color: _getStatusColor(
                              status ?? '',
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: _getStatusColor(status ?? ''),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking #${bookingId.substring(0, 8).toUpperCase()}',
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
                                  color: _getStatusColor(
                                    status ?? '',
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status ?? 'Unknown',
                                  style: TextStyle(
                                    color: _getStatusColor(status ?? ''),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (servicePrice != null)
                          Text(
                            '₹${servicePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Service Info
                    _buildInfoRow(
                      icon: Icons.business_center_rounded,
                      label: 'Service',
                      value: '$serviceProviderCategory - $serviceName',
                    ),
                    const SizedBox(height: 8),

                    // Customer Info
                    _buildInfoRow(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: customerName,
                    ),
                    const SizedBox(height: 8),

                    // Provider Info
                    _buildInfoRow(
                      icon: Icons.support_agent_rounded,
                      label: 'Provider',
                      value: serviceProviderName,
                    ),
                    const SizedBox(height: 8),

                    // Time Info
                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: bookingTime != null
                          ? DateFormat(
                              'MMM dd, yyyy • hh:mm a',
                            ).format(bookingTime.toDate())
                          : 'N/A',
                    ),

                    // Additional Info
                    if (status == 'Confirmed' &&
                        remarks != null &&
                        remarks.isNotEmpty) ...[
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

                    if (status == 'Canceled' &&
                        cancelReason != null &&
                        cancelReason.isNotEmpty) ...[
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

                      if (status == 'Completed') ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'This service has been completed successfully',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
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
