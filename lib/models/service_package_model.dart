// lib/models/service_package_model.dart

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
    // We add the null-aware operator (??) to provide a default value
    // in case the Firestore data is null or missing.
    return ServicePackage(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Package',
      description: data['description'] as String? ?? 'No description available.',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      durationInMinutes: data['durationInMinutes'] as int? ?? 0,
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
