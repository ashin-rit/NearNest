import 'package:flutter/material.dart';

class ShopDashboard extends StatelessWidget {
  const ShopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Dashboard')),
      body: const Center(
        child: Text(
          'Welcome, Shop!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}