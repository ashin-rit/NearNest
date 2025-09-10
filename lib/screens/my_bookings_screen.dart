import 'package:flutter/material.dart';
import 'package:nearnest/models/booking_model.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  /// Determines the color of the status text.
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  /// Fetches the category of the service provider.
  Future<String> _fetchServiceProviderCategory(String serviceProviderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(serviceProviderId)
          .get();
      if (doc.exists) {
        return doc.data()?['category'] ?? 'N/A';
      }
      return 'N/A';
    } catch (e) {
      print('Error fetching service provider category: $e');
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final BookingService _bookingService = BookingService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          StreamBuilder<List<Booking>>(
            stream: _bookingService.getUserBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('You have not made any bookings yet.'),
                );
              }

              final bookings = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: AuthService().getUserDataByUid(
                              booking.serviceProviderId,
                            ),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Service Provider: Loading...');
                              }
                              if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                                return const Text('Service Provider: Not Found');
                              }
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              final providerName = userData['name'] ?? 'N/A';
                              return FutureBuilder<String>(
                                future: _fetchServiceProviderCategory(booking.serviceProviderId),
                                builder: (context, categorySnapshot) {
                                  if (categorySnapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading category...');
                                  }
                                  final providerCategory = categorySnapshot.data ?? 'N/A';
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.business_center, size: 50, color: Colors.blueAccent),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Service Provider: $providerCategory',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          Text(
                                            'Name: $providerName',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildDetailRow(
                            icon: Icons.work_outline,
                            label: 'Service',
                            value: booking.serviceName,
                          ),
                          _buildDetailRow(
                            icon: Icons.currency_rupee,
                            label: 'Price',
                            value: '₹${booking.servicePrice!.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: DateFormat('MMM d, yyyy').format(booking.bookingTime.toDate().toLocal()),
                          ),
                          _buildDetailRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: DateFormat('h:mm a').format(booking.bookingTime.toDate().toLocal()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                booking.status,
                                style: TextStyle(
                                  color: _getStatusColor(booking.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (booking.status == 'Confirmed' && booking.remarks != null && booking.remarks!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Remarks: ${booking.remarks}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          if (booking.status == 'Canceled' && booking.cancellationReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Cancellation Reason: ${booking.cancellationReason}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
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
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
