// lib/screens/dashboards/user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/browse_screen.dart';
import 'package:nearnest/screens/favorites_screen.dart';
import 'package:nearnest/screens/my_orders_screen.dart';
import 'package:nearnest/screens/user_profile_screen.dart';
import 'package:nearnest/screens/my_bookings_screen.dart'; // Import the new screen

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BrowseScreen(),
    const FavoritesScreen(),
    const MyOrdersScreen(),
    const MyBookingsScreen(), // Add the new bookings screen
    const UserProfileScreen(),
  ];

  final List<String> _titles = [
    'NearNest - Browse',
    'My Favorites',
    'My Orders',
    'My Bookings', // Add the new title
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF34D399),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF34D399),
        unselectedItemColor: Colors.grey[700],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), // Use a relevant icon
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}