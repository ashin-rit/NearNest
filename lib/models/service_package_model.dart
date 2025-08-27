// lib/models/service_package_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicePackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationInMinutes;

  ServicePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInMinutes,
  });

  // Factory constructor to create a ServicePackage object from a Firestore document
  factory ServicePackage.fromMap(Map<String, dynamic> data, {required String id}) {
    return ServicePackage(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      durationInMinutes: data['durationInMinutes'] as int,
    );
  }

  // Method to convert a ServicePackage object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationInMinutes': durationInMinutes,
    };
  }
}