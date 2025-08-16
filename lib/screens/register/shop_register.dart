// lib/screens/register/shop_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class ShopsRegisterPage extends StatelessWidget {
  const ShopsRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Shop',
      'color': const Color(0xFF854D0E),
      'gradient': const [
        Color(0xFFFACC15),
        Color(0xFFEAB308),
        Color(0xFFCA8A04),
        Color(0xFFB45309),
      ],
      'icon': Icons.store,
      'title': 'Shop Registration',
      'subtitle': 'Register your shop to reach new customers'
    };

    return RegistrationPage(userConfig: userConfig);
  }
}