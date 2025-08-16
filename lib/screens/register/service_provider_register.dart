// lib/screens/register/service_provider_register.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/register/registration_page.dart';

class ServiceProviderRegisterPage extends StatelessWidget {
  const ServiceProviderRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = {
      'role': 'Service Provider',
      'color': const Color(0xFF0C4A6E),
      'gradient': const [
        Color(0xFF38BDF8),
        Color(0xFF0EA5E9),
        Color(0xFF0284C7),
        Color(0xFF0369A1),
      ],
      'icon': Icons.business_center,
      'title': 'Service Provider Registration',
      'subtitle': 'Join as a professional service provider'
    };



    return RegistrationPage(userConfig: userConfig);
  }
}