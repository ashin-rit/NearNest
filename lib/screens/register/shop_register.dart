// lib/screens/register/shop_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class ShopsRegisterPage extends StatelessWidget {
  const ShopsRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Shop',
      'color': const Color(0xFF92400E), // Updated to match login page
      'gradient': const [
        Color(0xFF92400E), // Amber-brown
        Color(0xFFB45309), // Orange-brown  
        Color(0xFFD97706), // Amber-orange
        Color(0xFFF59E0B), // Amber
      ], // Updated to match login page gradient
      'icon': Icons.storefront_rounded, // Modern rounded icon
      'title': 'Shop Registration',
      'subtitle': 'Register your shop and reach new customers online'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}