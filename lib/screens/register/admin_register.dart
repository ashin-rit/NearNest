// lib/screens/register/admin_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class AdminRegisterPage extends StatelessWidget {
  const AdminRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Admin',
      'color': const Color(0xFF991B1B),
      'gradient': const [
        Color(0xFFF87171),
        Color(0xFFEF4444),
        Color(0xFFDC2626),
        Color(0xFFB91C1C),
      ],
      'icon': Icons.security,
      'title': 'Admin Registration',
      'subtitle': 'Manage your application'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}