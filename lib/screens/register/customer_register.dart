// lib/screens/register/customer_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class CustomerRegisterPage extends StatelessWidget {
  const CustomerRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Customer',
      'color': const Color(0xFF06D6A0), // Updated to match login page
      'gradient': const [
        Color(0xFF06D6A0),
        Color(0xFF118AB2), 
        Color(0xFF073B4C),
        Color(0xFF0F3460),
      ], // Updated to match login page gradient
      'icon': Icons.people_alt_rounded, // Modern rounded icon
      'title': 'Customer Registration',
      'subtitle': 'Join our community and discover amazing services'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}