// lib/screens/register/customer_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class CustomerRegisterPage extends StatelessWidget {
  const CustomerRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Customer',
      'color': const Color(0xFF065F46),
      'gradient': const [
        Color(0xFF34D399),
        Color(0xFF10B981),
        Color(0xFF059669),
        Color(0xFF047857),
      ],
      'icon': Icons.people,
      'title': 'Customer Registration',
      'subtitle': 'Join our community today'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}