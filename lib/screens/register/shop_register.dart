// lib/screens/register/shop_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class ShopsRegisterPage extends StatelessWidget {
  const ShopsRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Shop',
      'color': const Color(0xFF6D28D9), // CHANGED: Primary purple
      'gradient': const [
        Color(0xFF4C1D95), // CHANGED: Deep purple
        Color(0xFF6D28D9), // CHANGED: Violet
        Color(0xFF7C3AED), // CHANGED: Purple
        Color(0xFF8B5CF6), // CHANGED: Light purple
      ], // Updated to match login page gradient
      'icon': Icons.storefront_rounded, // Modern rounded icon
      'title': 'Shop Registration',
      'subtitle': 'Register your shop and reach new customers online',
    };

    return RegistrationPage(userConfig: userConfig);
  }
}
