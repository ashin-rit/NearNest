// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceProviderId;
  final String serviceName;
  final String status;
  final Timestamp bookingTime;
  final String? taskDescription;
  final String? cancellationReason;
  final double? servicePrice; // New: Add this field
  final int? serviceDuration; // New: Add this field

  Booking({
    required this.id,
    required this.userId,
    required this.serviceProviderId,
    required this.serviceName,
    required this.status,
    required this.bookingTime,
    this.taskDescription,
    this.cancellationReason,
    this.servicePrice, // New: Add to the constructor
    this.serviceDuration, // New: Add to the constructor
  });

  // Factory constructor to create a Booking object from a Firestore document
  factory Booking.fromMap(Map<String, dynamic> data) {
    return Booking(
      id: data['id'] as String,
      userId: data['userId'] as String,
      serviceProviderId: data['serviceProviderId'] as String,
      serviceName: data['serviceName'] as String,
      status: data['status'] as String,
      bookingTime: data['bookingTime'] as Timestamp,
      taskDescription: data['taskDescription'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      servicePrice: (data['servicePrice'] as num?)?.toDouble(), // New: Retrieve the field
      serviceDuration: data['serviceDuration'] as int?, // New: Retrieve the field
    );
  }

  // Method to convert a Booking object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceProviderId': serviceProviderId,
      'serviceName': serviceName,
      'status': status,
      'bookingTime': bookingTime,
      'taskDescription': taskDescription,
      'cancellationReason': cancellationReason,
      'servicePrice': servicePrice, // New: Add the field to the map
      'serviceDuration': serviceDuration, // New: Add the field to the map
    };
  }
}