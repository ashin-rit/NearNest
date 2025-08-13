import 'package:flutter/material.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> userRoles = [
    {'role': 'Admin', 'icon': Icons.admin_panel_settings, 'route': '/admin_login'},
    {'role': 'Customer', 'icon': Icons.people, 'route': '/customer_login'},
    {'role': 'Service Provider', 'icon': Icons.assignment_ind, 'route': '/service_provider_login'},
    {'role': 'Shops', 'icon': Icons.storefront, 'route': '/shop_login'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushNamed(context, userRoles[index]['route']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Your Role to Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            // You can replace this placeholder with a more visually appealing widget
            // or simply have an empty screen and rely on the bottom navigation.
            Image.asset(
              'assets/logo.png', // Replace with your app logo
              height: 150,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: userRoles.map((role) {
          return BottomNavigationBarItem(
            icon: Icon(role['icon']),
            label: role['role'],
          );
        }).toList(),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 12,
        showUnselectedLabels: true,
      ),
    );
  }
}