// lib/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:nearnest/models/booking_model.dart';
import 'package:nearnest/services/booking_service.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookingService _bookingService = BookingService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder<List<Booking>>(
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
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
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
                      if (booking.servicePrice != null && booking.serviceDuration != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price: ₹${booking.servicePrice!.toStringAsFixed(2)}',
                            ),
                            Text('Duration: ${booking.serviceDuration} mins'),
                            const SizedBox(height: 8),
                          ],
                        ),
                      Text(
                        'Date: ${booking.bookingTime.toDate().toLocal().toString().split(' ')[0]}',
                      ),
                      Text(
                        'Time: ${booking.bookingTime.toDate().toLocal().toString().split(' ')[1].substring(0, 5)}',
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: AuthService().getUserDataByUid(
                          booking.serviceProviderId,
                        ),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Service Provider: Loading...');
                          }
                          if (userSnapshot.hasError ||
                              !userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const Text('Service Provider: Not Found');
                          }
                          final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                          return Text(
                            'Service Provider: ${userData['name'] ?? 'N/A'}',
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Status: ${booking.status}'),
                      // Display remarks if the booking is confirmed
                      if (booking.status == 'Confirmed' &&
                          booking.remarks != null &&
                          booking.remarks!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Remarks: ${booking.remarks}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      // Display cancellation reason if the booking is canceled
                      if (booking.status == 'Canceled' &&
                          booking.cancellationReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Cancellation Reason: ${booking.cancellationReason}',
                            style: const TextStyle(color: Colors.red),
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
    );
  }
}