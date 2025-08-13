import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Dashboard')),
      body: const Center(
        child: Text(
          'Welcome, Customer!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}