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
  final String? remarks;
  final String? cancellationReason;
  final double? servicePrice;
  final int? serviceDuration;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceProviderId,
    required this.serviceName,
    required this.status,
    required this.bookingTime,
    this.taskDescription,
    this.remarks,
    this.cancellationReason,
    this.servicePrice,
    this.serviceDuration,
  });

  factory Booking.fromMap(Map<String, dynamic> data) {
    return Booking(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      serviceProviderId: data['serviceProviderId'] ?? '',
      serviceName: data['serviceName'] ?? 'N/A',
      status: data['status'] ?? 'Pending',
      bookingTime: data['bookingTime'] ?? Timestamp.now(),
      taskDescription: data['taskDescription'],
      remarks: data['remarks'],
      cancellationReason: data['cancellationReason'],
      servicePrice: (data['servicePrice'] as num?)?.toDouble(),
      serviceDuration: (data['serviceDuration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceProviderId': serviceProviderId,
      'serviceName': serviceName,
      'status': status,
      'bookingTime': bookingTime,
      'taskDescription': taskDescription,
      'remarks': remarks,
      'cancellationReason': cancellationReason,
      'servicePrice': servicePrice,
      'serviceDuration': serviceDuration,
    };
  }
}