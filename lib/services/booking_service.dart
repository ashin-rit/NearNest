// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to create a new booking
  Future<void> createBooking({
    required String serviceProviderId,
    required String serviceName,
    required Timestamp bookingTime,
    String? taskDescription,
    required double servicePrice, // New: Add this parameter
    required int serviceDuration, // New: Add this parameter
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Reference to the bookings collection
    final bookingRef = _firestore.collection('bookings').doc();

    final newBooking = Booking(
      id: bookingRef.id,
      userId: user.uid,
      serviceProviderId: serviceProviderId,
      serviceName: serviceName,
      status: 'Pending', // Initial status
      bookingTime: bookingTime,
      taskDescription: taskDescription,
      servicePrice: servicePrice, // New: Pass the price to the model
      serviceDuration: serviceDuration, // New: Pass the duration to the model
    );

    await bookingRef.set(newBooking.toMap());
  }

  // New: Method to update the status of a booking
  Future<void> updateBookingStatus(
      String bookingId, String newStatus, {String? cancellationReason}) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final updateData = {
      'status': newStatus,
      'cancellationReason': cancellationReason,
    };
    await bookingRef.update(updateData);
  }

  // Method to get a stream of bookings for a specific user
  Stream<List<Booking>> getUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();
    });
  }

  // Method to get a stream of bookings for a specific service provider
  Stream<List<Booking>> getServiceProviderBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: user.uid)
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();
    });
  }
}