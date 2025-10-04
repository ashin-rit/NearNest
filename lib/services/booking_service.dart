// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to create a new booking
  Future<String?> createBooking({
    required String serviceProviderId,
    required String serviceName,
    required Timestamp bookingTime,
    String? taskDescription,
    required double servicePrice,
    required int serviceDuration,
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
      status: 'Pending',
      bookingTime: bookingTime,
      taskDescription: taskDescription,
      servicePrice: servicePrice,
      serviceDuration: serviceDuration,
    );

    await bookingRef.set(newBooking.toMap());
    return bookingRef.id;
  }

  // Method to update booking details (edit functionality)
  Future<void> updateBooking({
    required String bookingId,
    Timestamp? newBookingTime,
    String? newTaskDescription,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Check if booking exists and belongs to current user
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    
    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }
    
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    if (bookingData['userId'] != user.uid) {
      throw Exception('You can only edit your own bookings.');
    }

    // Check if booking can be edited (only pending bookings)
    if (bookingData['status']?.toLowerCase() != 'pending') {
      throw Exception('Only pending bookings can be edited.');
    }

    final updateData = <String, dynamic>{};
    
    if (newBookingTime != null) {
      updateData['bookingTime'] = newBookingTime;
    }
    
    if (newTaskDescription != null) {
      updateData['taskDescription'] = newTaskDescription;
    }

    if (updateData.isNotEmpty) {
      await _firestore.collection('bookings').doc(bookingId).update(updateData);
    }
  }

  // Method to cancel/delete booking
  Future<void> cancelBooking(String bookingId, {String? cancellationReason}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Check if booking exists and belongs to current user
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    
    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }
    
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    if (bookingData['userId'] != user.uid) {
      throw Exception('You can only cancel your own bookings.');
    }

    // Check if booking can be cancelled
    final currentStatus = bookingData['status']?.toLowerCase();
    if (currentStatus == 'canceled' || currentStatus == 'cancelled') {
      throw Exception('Booking is already cancelled.');
    }

    // Update booking status to cancelled
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'Canceled',
      'cancellationReason': cancellationReason ?? 'Cancelled by user',
    });
  }

  // Method to permanently delete booking (only for cancelled bookings)
  Future<void> deleteBooking(String bookingId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }

    // Check if booking exists and belongs to current user
    final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
    
    if (!bookingDoc.exists) {
      throw Exception('Booking not found.');
    }
    
    final bookingData = bookingDoc.data() as Map<String, dynamic>;
    if (bookingData['userId'] != user.uid) {
      throw Exception('You can only delete your own bookings.');
    }

    // Only allow deletion of cancelled bookings
    final currentStatus = bookingData['status']?.toLowerCase();
    if (currentStatus != 'pending' ) {
      throw Exception('Only pending bookings can be permanently deleted.');
    }

    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  // Method to get a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching booking: $e');
      return null;
    }
  }

  // Method to update the status of a booking (for service providers)
  Future<void> updateBookingStatus(
      String bookingId, String newStatus, {String? cancellationReason, String? remarks}) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    final updateData = {
      'status': newStatus,
      'cancellationReason': cancellationReason,
      'remarks': remarks,
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

  // Helper method to check if booking can be edited
  bool canEditBooking(Booking booking) {
    return booking.status.toLowerCase() == 'pending';
  }

  // Helper method to check if booking can be cancelled
  bool canCancelBooking(Booking booking) {
    final status = booking.status.toLowerCase();
    return status != 'canceled' && status != 'cancelled';
  }
}