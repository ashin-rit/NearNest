// lib/screens/dashboards/user_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearnest/screens/browse_screen.dart';
import 'package:nearnest/screens/favorites_screen.dart';
import 'package:nearnest/screens/cart_screen.dart';
import 'package:nearnest/screens/my_orders_screen.dart';
import 'package:nearnest/screens/user_profile_screen.dart';
import 'package:nearnest/screens/my_bookings_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const BrowseScreen(),
    const FavoritesScreen(),
    const CartScreen(),
    const MyOrdersScreen(),
    const MyBookingsScreen(),
    const UserProfileScreen(),
  ];

  final List<String> _titles = [
    'Browse',
    'Favorites',
    'My Cart',
    'Orders',
    'Bookings',
    'Profile',
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.shopping_cart_rounded,
    Icons.receipt_rounded,
    Icons.calendar_today_rounded,
    Icons.person_rounded,
  ];

  final List<Color> _colors = [
    const Color(0xFF10B981), // Browse - Green
    const Color(0xFFEC4899), // Favorites - Pink
    const Color(0xFF6366F1), // Cart - Indigo
    const Color(0xFF3B82F6), // Orders - Blue
    const Color(0xFF8B5CF6), // Bookings - Purple
    const Color(0xFF059669), // Profile - Dark Green
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      HapticFeedback.lightImpact();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _pages[index];
        },
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_pages.length, (index) {
          final isSelected = index == _currentIndex;
          return GestureDetector(
            onTap: () => _onTabTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _colors[index].withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _colors[index]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _icons[index],
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: isSelected ? 22 : 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 12 : 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? _colors[index]
                          : Colors.grey[600],
                    ),
                    child: Text(_titles[index]),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}