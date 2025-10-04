// lib/screens/dashboards/service_provider_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/models/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nearnest/services/one_signal_notification_sender.dart';

class ServiceProviderBookingsScreen extends StatefulWidget {
  const ServiceProviderBookingsScreen({super.key});

  @override
  State<ServiceProviderBookingsScreen> createState() =>
      _ServiceProviderBookingsScreenState();
}

class _ServiceProviderBookingsScreenState
    extends State<ServiceProviderBookingsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedStatus = 'All';
  bool _sortAscending = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _cancelReasonController = TextEditingController();
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Canceled',
  ];

  final Map<String, Color> _statusColors = {
    'All': const Color(0xFF6B7280),
    'Pending': const Color(0xFFF59E0B),
    'Confirmed': const Color(0xFF10B981),
    'Completed': const Color(0xFF8B5CF6),
    'Canceled': const Color(0xFFEF4444),
  };

  final Map<String, IconData> _statusIcons = {
    'All': Icons.all_inclusive,
    'Pending': Icons.schedule,
    'Confirmed': Icons.check_circle,
    'Completed': Icons.task_alt,
    'Canceled': Icons.cancel,
  };

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _filterAnimationController.forward();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _cancelReasonController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

Future<void> _updateBookingStatus(
  String bookingId,
  String newStatus, {
  String? cancellationReason,
  String? remarks,
}) async {
  try {
    final updateData = <String, dynamic>{'status': newStatus};
    if (remarks != null) {
      updateData['remarks'] = remarks;
    }
    if (cancellationReason != null) {
      updateData['cancellationReason'] = cancellationReason;
    }

    // Update booking in Firestore
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update(updateData);

    // 🔔 SEND NOTIFICATION TO CUSTOMER
    try {
      // Get service provider name
      final providerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final providerName = providerDoc.data()?['name'] ?? 'Your service provider';

      // Get customer ID and service name from booking
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      final bookingData = bookingDoc.data();
      final customerId = bookingData?['userId'];
      final serviceName = bookingData?['serviceName'] ?? 'service';

      if (customerId != null) {
        await OneSignalNotificationSender.notifyCustomerBookingStatusChange(
          customerId: customerId,
          bookingId: bookingId,
          newStatus: newStatus,
          serviceProviderName: providerName,
          serviceName: serviceName,
          remarks: newStatus.toLowerCase() == 'canceled' ? cancellationReason : remarks,
        );
        print('✅ Customer notified of booking status change');
      }
    } catch (e) {
      print('❌ Error sending notification to customer: $e');
      // Don't block the UI if notification fails
    }

    _showSnackBar(
      'Booking status updated to $newStatus!',
      _statusColors[newStatus] ?? Colors.blue,
    );
  } catch (e) {
    _showSnackBar('Failed to update booking status: $e', Colors.red);
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

  void _showBookingActionDialog(
    BuildContext context,
    String bookingId,
    String status,
    String? currentRemarks,
  ) {
    if (status == 'Pending') {
      _remarksController.text = currentRemarks ?? '';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
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
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Color(0xFFF59E0B),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pending Booking Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: 'Add remarks for customer',
                        prefixIcon: Icon(
                          Icons.note_add,
                          color: Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        labelStyle: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateBookingStatus(
                              bookingId,
                              'Confirmed',
                              remarks: _remarksController.text,
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showCancelDialog(context, bookingId);
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel Booking'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (status == 'Confirmed') {
      _showCompleteDialog(context, bookingId);
    }
  }

  void _showCompleteDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    color: Color(0xFF8B5CF6),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complete Service',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mark this booking as completed?',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateBookingStatus(bookingId, 'Completed');
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Mark Completed',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

  void _showCancelDialog(BuildContext context, String bookingId) {
    _cancelReasonController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
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
                    Icons.cancel_outlined,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    color: const Color(0xFFF9FAFB),
                  ),
                  child: TextField(
                    controller: _cancelReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for cancellation',
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: Color(0xFF6B7280),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      labelStyle: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_cancelReasonController.text.isNotEmpty) {
                            _updateBookingStatus(
                              bookingId,
                              'Canceled',
                              cancellationReason: _cancelReasonController.text,
                            );
                            Navigator.of(context).pop();
                          } else {
                            _showSnackBar(
                              'Please enter a cancellation reason.',
                              Colors.orange,
                            );
                          }
                        },
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
                          'Confirm Cancellation',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<Map<String, dynamic>> _fetchCustomerData(String userId) async {
    if (userId.isNotEmpty) {
      final customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (customerDoc.exists) {
        return customerDoc.data() as Map<String, dynamic>;
      }
    }
    return {'name': 'Unknown Customer'};
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final String? serviceProviderId = _auth.currentUser?.uid;

    if (serviceProviderId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: Text(
            'Service Provider not logged in.',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: serviceProviderId);

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    query = query.orderBy('bookingTime', descending: _sortAscending);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
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
      body: Column(
        children: [
          // Modern filter chips
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: FadeTransition(
              opacity: _filterAnimation,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusOptions.length,
                itemBuilder: (context, index) {
                  final status = _statusOptions[index];
                  final isSelected = _selectedStatus == status;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcons[status],
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : _statusColors[status],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : _statusColors[status],
                            ),
                          ),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: _statusColors[status],
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? _statusColors[status]!
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: isSelected ? 4 : 0,
                      shadowColor: _statusColors[status]?.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
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
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 60,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _selectedStatus == 'All'
                              ? 'No bookings found'
                              : 'No $_selectedStatus bookings',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your bookings will appear here when customers book your services',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bookings = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking =
                        bookings[index].data() as Map<String, dynamic>;
                    final String bookingId = bookings[index].id;
                    final String status = booking['status'] ?? 'Unknown';
                    final String userId = booking['userId'] ?? 'Unknown';
                    final Timestamp bookingTime = booking['bookingTime'];
                    final String serviceName =
                        booking['serviceName'] ?? 'Unknown Service';
                    final String? taskDescription = booking['taskDescription'];
                    final String? remarks = booking['remarks'];
                    final String? cancelReason = booking['cancellationReason'];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _fetchCustomerData(userId),
                      builder: (context, customerSnapshot) {
                        final customerData =
                            customerSnapshot.data ?? {'name': 'Loading...'};
                        final customerName =
                            customerData['name'] ?? 'Unknown Customer';
                        final bool hasLocation =
                            customerData['latitude'] != null &&
                            customerData['longitude'] != null;

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
                          child: InkWell(
                            onTap: () {
                              if (status == 'Pending' ||
                                  status == 'Confirmed') {
                                _showBookingActionDialog(
                                  context,
                                  bookingId,
                                  status,
                                  remarks,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
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
                                          color: _getStatusColor(
                                            status,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          _statusIcons[status] ?? Icons.help,
                                          color: _getStatusColor(status),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customerName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy • hh:mm a',
                                              ).format(bookingTime.toDate()),
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            status,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.business_center,
                                              size: 16,
                                              color: Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Service Details',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          serviceName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (taskDescription != null &&
                                            taskDescription.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            taskDescription,
                                            style: const TextStyle(
                                              color: Color(0xFF6B7280),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Customer Actions Row
                                  if (hasLocation) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.05),
                                            Colors.cyan.withOpacity(0.03),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_city_rounded,
                                                size: 14,
                                                color: Colors.blue[700],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Customer Location',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showCustomerLocationDialog(
                                                    context,
                                                    customerData,
                                                  ),
                                              icon: const Icon(
                                                Icons.location_on_rounded,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'View Location',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (remarks != null &&
                                      remarks.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.note,
                                            size: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Remarks: $remarks',
                                              style: const TextStyle(
                                                color: Color(0xFF065F46),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (cancelReason != null &&
                                      cancelReason.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Reason: $cancelReason',
                                              style: const TextStyle(
                                                color: Color(0xFF991B1B),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (status == 'Pending') ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF4F46E5,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.touch_app,
                                            size: 16,
                                            color: Color(0xFF4F46E5),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tap to take action on this booking',
                                            style: TextStyle(
                                              color: Color(0xFF4F46E5),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (status == 'Confirmed') ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.task_alt,
                                            size: 16,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tap to mark as completed',
                                            style: TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Booking ID: $bookingId',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
