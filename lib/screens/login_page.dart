// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/screens/awaiting_approval_page.dart';

// Import the new services and common widgets
import 'package:nearnest/screens/common_widgets.dart';
import 'package:nearnest/services/auth_service.dart';

// Import the new dashboard pages
import 'package:nearnest/screens/dashboards/admin_dashboard.dart';
import 'package:nearnest/screens/dashboards/service_provider_dashboard.dart';
import 'package:nearnest/screens/dashboards/shop_dashboard.dart';
import 'package:nearnest/screens/dashboards/user_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<Map<String, dynamic>> users = [
    {
      'role': 'Admin',
      'icon': Icons.security,
      'colors': [
        const Color(0xFFF87171),
        const Color(0xFFEF4444),
        const Color(0xFFDC2626),
        const Color(0xFFB91C1C),
      ],
      'color': const Color(0xFF991B1B),
    },
    {
      'role': 'Customer',
      'icon': Icons.people,
      'colors': [
        const Color(0xFF34D399),
        const Color(0xFF10B981),
        const Color(0xFF059669),
        const Color(0xFF047857),
      ],
      'color': const Color(0xFF065F46),
    },
    {
      'role': 'Services',
      'icon': Icons.business_center,
      'colors': [
        const Color(0xFF38BDF8),
        const Color(0xFF0EA5E9),
        const Color(0xFF0284C7),
        const Color(0xFF0369A1),
      ],
      'color': const Color(0xFF0C4A6E),
    },
    {
      'role': 'Shops',
      'icon': Icons.store,
      'colors': [
        const Color(0xFFFACC15),
        const Color(0xFFEAB308),
        const Color(0xFFCA8A04),
        const Color(0xFFB45309),
      ],
      'color': const Color(0xFF854D0E),
    },
  ];

  int selectedIndex = 1;
  bool isLoading = false;
  String error = '';
  bool showPassword = false;

  void _showSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: isError ? Colors.white : Colors.black),
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userUid = userCredential.user?.uid;
      if (userUid != null) {
        final userDoc = await _authService.getUserDataByUid(userUid);

        // Crucial: Check if the user document exists and has data to prevent errors
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final role = userData['role'];
          final status = userData['status'] ?? 'approved';

          if ((role == 'Shop' || role == 'Services') && status == 'pending') {
            // Navigate to the awaiting approval page if status is pending
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AwaitingApprovalPage(),
              ),
            );
            return;
          }

          // Navigate directly to the dashboard if status is approved or not pending
          _navigateToDashboard(role);
          _showSnackBar('Login successful', isError: false);
        } else {
          // If the document doesn't exist, sign the user out to prevent issues
          await _authService.signOut();
          _showSnackBar('User data not found. Please contact support.', isError: true);
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      setState(() {
        error = 'An unknown error occurred.';
      });
      _showSnackBar('An unknown error occurred.', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToDashboard(String role) {
    Widget dashboard;
    switch (role) {
      case 'Admin':
        dashboard = const AdminDashboard();
        break;
      case 'Shop':
        dashboard = const ShopDashboard();
        break;
      case 'Services':
        dashboard = const ServiceProviderDashboard();
        break;
      case 'Customer':
      default:
        dashboard = const UserDashboard();
        break;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => dashboard));
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      message = 'Invalid email or password.';
    } else if (e.code == 'invalid-email') {
      message = 'The email address is not valid.';
    } else if (e.code == 'user-disabled') {
      // Add a specific message for disabled users
      message = 'This account has been disabled. Please contact support for assistance.';
    } else {
      message = e.message ?? 'An unknown authentication error occurred.';
    }
    setState(() {
      error = message;
    });
    _showSnackBar(message, isError: true);
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Map<String, dynamic> selectedUser = users[selectedIndex];
    final List<Color> gradientColors = selectedUser['colors'];
    final Color primaryColor = selectedUser['color'];

    return Scaffold(
      body: CustomGradientBackground(
        gradientColors: gradientColors,
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUserSelection(primaryColor),
                        const SizedBox(height: 50),
                        _buildLoginContent(primaryColor, size),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelection(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: users.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> user = entry.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: selectedIndex == index
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Icon(user['icon'], color: Colors.white),
                    const SizedBox(height: 5),
                    Text(
                      user['role'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoginContent(Color primaryColor, Size size) {
    final selectedUser = users[selectedIndex];

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Login as ${selectedUser['role']}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 25),
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          // Conditionally hide these buttons for the Admin role
          if (selectedUser['role'] != 'Admin') ...[
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                // TODO: Implement forgot password logic
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                final role = selectedUser['role'].toLowerCase();
                final routeName = '/${role.replaceAll(' ', '_')}_registration';
                Navigator.of(context).pushNamed(routeName);
              },
              child: Text(
                "Don't have an account? Sign Up",
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !showPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}