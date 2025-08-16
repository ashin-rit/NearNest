// lib/screens/register/registration_page.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/common_widgets.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationPage extends StatefulWidget {
  final Map<String, dynamic> userConfig;

  const RegistrationPage({super.key, required this.userConfig});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final AuthService _authService = AuthService();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String error = '';
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool acceptTerms = false;

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

  Future<void> _handleRegistration() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }

    if (!acceptTerms) {
      _showSnackBar('You must accept the terms and conditions.', isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final userData = {
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': widget.userConfig['role'],
        'status': 'pending',
      };

      await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
      );

      _showSnackBar('Registration successful! Welcome.', isError: false);
      _clearFormFields();
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

  void _clearFormFields() {
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      acceptTerms = false;
    });
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'The account already exists for that email.';
    } else {
      message = 'Registration failed: ${e.message}';
    }
    setState(() {
      error = message;
    });
    _showSnackBar(message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userConfig = widget.userConfig;
    final List<Color> gradientColors = userConfig['gradient'];
    final Color primaryColor = userConfig['color'];

    return Scaffold(
      body: CustomGradientBackground(
        gradientColors: gradientColors,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.userConfig['icon'],
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.userConfig['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    widget.userConfig['subtitle'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildForm(primaryColor),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(Color primaryColor) {
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
        children: [
          _buildTextField(
            controller: _fullNameController,
            hint: 'Full Name',
            icon: Icons.person,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _phoneController,
            hint: 'Phone Number',
            icon: Icons.phone,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _addressController,
            hint: 'Address',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Confirm Password',
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 15),
          _buildTermsAndConditions(primaryColor),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: isLoading ? null : _handleRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'Register',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
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

  Widget _buildTermsAndConditions(Color primaryColor) {
    return Row(
      children: [
        Checkbox(
          value: acceptTerms,
          onChanged: (bool? newValue) {
            setState(() {
              acceptTerms = newValue!;
            });
          },
          activeColor: primaryColor,
        ),
        const Expanded(
          child: Text(
            'I agree to the terms and conditions',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}