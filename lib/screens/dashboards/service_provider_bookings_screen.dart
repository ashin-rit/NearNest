// lib/screens/dashboards/service_provider_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/models/booking_model.dart';

class ServiceProviderBookingsScreen extends StatefulWidget {
  const ServiceProviderBookingsScreen({super.key});

  @override
  State<ServiceProviderBookingsScreen> createState() => _ServiceProviderBookingsScreenState();
}

class _ServiceProviderBookingsScreenState extends State<ServiceProviderBookingsScreen> {
  final BookingService _bookingService = BookingService();

  Future<void> _updateBookingStatus(String bookingId, String newStatus, {String? cancellationReason}) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, newStatus, cancellationReason: cancellationReason);
      if (newStatus == 'Confirmed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking confirmed successfully!')),
        );
      } else if (newStatus == 'Canceled') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking canceled successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking status: $e')),
      );
    }
  }

  Future<void> _showCancellationDialog(String bookingId) async {
    final TextEditingController reasonController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please provide a reason for the cancellation.'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Go Back'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cancel Booking'),
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  _updateBookingStatus(bookingId, 'Canceled', cancellationReason: reasonController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cancellation reason cannot be empty.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingService.getServiceProviderBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no new bookings.'));
          }

          final bookings = snapshot.data!;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service: ${booking.serviceName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${booking.bookingTime.toDate().toLocal().toString().split(' ')[0]}',
                      ),
                      Text(
                        'Time: ${booking.bookingTime.toDate().toLocal().toString().split(' ')[1].substring(0, 5)}',
                      ),
                      const SizedBox(height: 8),
                      if (booking.taskDescription != null && booking.taskDescription!.isNotEmpty)
                        Text(
                          'Task: ${booking.taskDescription}',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                        ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: AuthService().getUserDataByUid(booking.userId),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                            return const Text('Customer: Not Found');
                          }
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          return Text(
                            'Customer: ${userData['name'] ?? 'N/A'}',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(booking.status),
                          const Spacer(),
                          if (booking.status == 'Pending') ...[
                            ElevatedButton(
                              onPressed: () => _updateBookingStatus(booking.id, 'Confirmed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Confirm'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showCancellationDialog(booking.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}