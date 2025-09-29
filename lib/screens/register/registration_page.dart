// lib/screens/register/registration_page.dart
import 'package:flutter/material.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  final Map<String, dynamic> userConfig;

  const RegistrationPage({super.key, required this.userConfig});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool isLoading = false;
  String error = '';
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool acceptTerms = false;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      backgroundColor: isError 
          ? const Color(0xFFE53E3E).withOpacity(0.9)
          : widget.userConfig['color'].withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 8,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String? _validateField(String? value, String fieldName, {int minLength = 1}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegistration() async {
    if (widget.userConfig['role'] == 'admin') {
      return;
    }

    if (!_formKey.currentState!.validate()) {
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
      final fullAddress =
          '${_streetAddressController.text}, ${_cityController.text}, ${_stateController.text}, India - ${_pincodeController.text}';
      
      GeoPoint? geoPoint;
      try {
        List<Location> locations = await locationFromAddress(fullAddress);
        if (locations.isNotEmpty) {
          geoPoint = GeoPoint(locations.first.latitude, locations.first.longitude);
        } else {
          _showSnackBar('Could not get precise location. Please check your address.', isError: true);
          setState(() {
            isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Geocoding failed during registration: $e');
        _showSnackBar('Could not get precise location. Please check your address.', isError: true);
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userData = {
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'streetAddress': _streetAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'role': widget.userConfig['role'],
        'status': 'pending',
        'location': geoPoint,
      };
      
      if (widget.userConfig['role'] == 'Shop' || widget.userConfig['role'] == 'Services') {
        userData['averageRating'] = 0.0;
        userData['reviewCount'] = 0;
      }

      await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
      );

      _showSnackBar('Registration successful! Welcome to NearNest.', isError: false);
      _clearFormFields();
      
      // Navigate back or to appropriate page
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
      
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
    _streetAddressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      acceptTerms = false;
      currentStep = 0;
    });
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'An account already exists for that email.';
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
    final size = MediaQuery.of(context).size;
    final userConfig = widget.userConfig;
    final List<Color> gradientColors = userConfig['gradient'];
    final Color primaryColor = userConfig['color'];

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background matching login pages
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradientColors[0].withOpacity(0.9),
                  gradientColors[1].withOpacity(0.8),
                  gradientColors[2].withOpacity(0.7),
                  gradientColors[3].withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Floating background elements
          ...List.generate(5, (index) => _buildFloatingShape(index, userConfig)),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.03),
                      _buildHeader(userConfig),
                      SizedBox(height: size.height * 0.04),
                      _buildRegistrationForm(primaryColor),
                      SizedBox(height: size.height * 0.03),
                      _buildFooter(),
                      SizedBox(height: size.height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (isLoading) _buildLoadingOverlay(primaryColor),
        ],
      ),
    );
  }

  Widget _buildFloatingShape(int index, Map<String, dynamic> userConfig) {
    final roleIcons = {
      'Customer': [Icons.people, Icons.favorite, Icons.star, Icons.location_on, Icons.search],
      'Services': [Icons.business_center, Icons.handyman, Icons.build, Icons.engineering, Icons.design_services],
      'Shop': [Icons.store, Icons.shopping_bag, Icons.inventory, Icons.point_of_sale, Icons.storefront],
    };
    
    final icons = roleIcons[userConfig['role']] ?? [Icons.circle];
    final random = (index * 181) % 100;
    final left = (random / 100) * MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: 100 + (index * 120.0),
          child: Transform.scale(
            scale: 0.3 + (_pulseAnimation.value * 0.2),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icons[index % icons.length],
                color: Colors.white.withOpacity(0.4),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> userConfig) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Animated role icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        userConfig['color'].withOpacity(0.8),
                        userConfig['gradient'][1].withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: userConfig['color'].withOpacity(0.4),
                        spreadRadius: 8,
                        blurRadius: 25,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      userConfig['icon'],
                      size: 42,
                      color: userConfig['color'],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              userConfig['title'],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              userConfig['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(Color primaryColor) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Personal Information Section
                _buildSectionHeader('Personal Information', Icons.person_rounded),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _fullNameController,
                  hint: 'Full Name',
                  icon: Icons.person_rounded,
                  validator: (value) => _validateField(value, 'Full name', minLength: 2),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _emailController,
                  hint: 'Email Address',
                  icon: Icons.email_rounded,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _phoneController,
                  hint: 'Phone Number',
                  icon: Icons.phone_rounded,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 24),
                
                // Address Section
                _buildSectionHeader('Address Information', Icons.location_on_rounded),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _streetAddressController,
                  hint: 'Street Address',
                  icon: Icons.home_rounded,
                  validator: (value) => _validateField(value, 'Street address'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        controller: _cityController,
                        hint: 'City',
                        icon: Icons.location_city_rounded,
                        validator: (value) => _validateField(value, 'City'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _stateController,
                        hint: 'State',
                        icon: Icons.map_rounded,
                        validator: (value) => _validateField(value, 'State'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _pincodeController,
                  hint: 'Pincode',
                  icon: Icons.local_post_office_rounded,
                  validator: (value) => _validateField(value, 'Pincode'),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 24),
                
                // Security Section
                _buildSectionHeader('Account Security', Icons.security_rounded),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  validator: _validatePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm Password',
                  icon: Icons.lock_rounded,
                  validator: _validateConfirmPassword,
                  isPassword: true,
                  isConfirmPassword: true,
                ),
                
                const SizedBox(height: 24),
                _buildTermsAndConditions(primaryColor),
                const SizedBox(height: 28),
                _buildRegisterButton(primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.userConfig['color'],
                widget.userConfig['gradient'][1],
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: isPassword 
            ? (isConfirmPassword ? !showConfirmPassword : !showPassword)
            : false,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.userConfig['color'], widget.userConfig['gradient'][1]],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isConfirmPassword ? showConfirmPassword : showPassword) 
                        ? Icons.visibility_off_rounded 
                        : Icons.visibility_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmPassword) {
                        showConfirmPassword = !showConfirmPassword;
                      } else {
                        showPassword = !showPassword;
                      }
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.userConfig['color'], width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: acceptTerms,
              onChanged: (bool? newValue) {
                setState(() {
                  acceptTerms = newValue!;
                });
              },
              activeColor: primaryColor,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'I agree to the Terms & Conditions and Privacy Policy',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(Color primaryColor) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isLoading 
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : [primaryColor, widget.userConfig['gradient'][1]],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          if (!isLoading) BoxShadow(
            color: primaryColor.withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Creating Account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/landing'),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Colors.white),
            label: Text(
              'Back to Role Selection',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(Color primaryColor) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 4,
                    ),
                  ),
                  Icon(
                    widget.userConfig['icon'],
                    color: primaryColor,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Creating Your Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Setting up your profile and verifying location...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}