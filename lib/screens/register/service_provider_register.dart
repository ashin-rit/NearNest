// lib/screens/register/service_provider_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class ServiceProviderRegisterPage extends StatelessWidget {
  const ServiceProviderRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Services',
      'color': const Color(0xFF0EA5E9), // Updated to match login page
      'gradient': const [
        Color(0xFF0F172A), // Dark blue
        Color(0xFF1E293B), // Slate
        Color(0xFF0EA5E9), // Sky blue
        Color(0xFF38BDF8), // Light blue
      ], // Updated to match login page gradient
      'icon': Icons.business_center_rounded, // Modern rounded icon
      'title': 'Service Provider Registration',
      'subtitle': 'Join as a professional and grow your business'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}