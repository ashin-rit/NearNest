import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  

class CustomerRegisterPage extends StatefulWidget {
  const CustomerRegisterPage({super.key});

  @override
  _CustomerRegisterPageState createState() => _CustomerRegisterPageState();
}

class _CustomerRegisterPageState extends State<CustomerRegisterPage> with TickerProviderStateMixin {
  final Map<String, dynamic> userConfig = {
    'role': 'Customer',
    'color': const Color(0xFF065F46),
    'gradient': const [
      Color(0xFF34D399),
      Color(0xFF10B981),
      Color(0xFF059669),
      Color(0xFF047857),
    ],
    'icon': Icons.people,
    'title': 'Customer Registration',
    'subtitle': 'Join our community today'
  };

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String error = '';
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool acceptTerms = false;

  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : userConfig['color'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 2.5,
                  colors: [
                    userConfig['color'].withOpacity(0.12),
                    const Color(0xFFF1F5F9).withOpacity(0.8),
                    const Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: isSmallScreen ? 8 : 16,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight: screenHeight * 0.85,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                            spreadRadius: -4,
                          ),
                          BoxShadow(
                            color: userConfig['color'].withOpacity(0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Section
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: isSmallScreen ? 24 : 32,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: userConfig['gradient'],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: userConfig['color'].withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    userConfig['icon'],
                                    color: Colors.white,
                                    size: isSmallScreen ? 28 : 32,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                Text(
                                  userConfig['title'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 26 : 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  userConfig['subtitle'],
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 15,
                                    color: Colors.white.withOpacity(0.95),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          // Registration Form
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: isSmallScreen ? 20 : 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name Field
                                _buildTextField('Full Name', 'Enter your full name', _fullNameController, Icons.person_outline),
                                
                                SizedBox(height: isSmallScreen ? 18 : 20),
                                
                                // Email Field
                                _buildTextField('Email Address', 'Enter your email', _emailController, Icons.email_outlined),
                                
                                SizedBox(height: isSmallScreen ? 18 : 20),
                                
                                // Phone Number Field
                                _buildTextField('Phone Number', 'Enter your phone number', _phoneController, Icons.phone_outlined),
                                
                                SizedBox(height: isSmallScreen ? 18 : 20),
                                
                                // Address Field
                                _buildTextField('Address', 'Enter your address', _addressController, Icons.home_outlined),
                                
                                SizedBox(height: isSmallScreen ? 18 : 20),
                                
                                // Password Field
                                _buildPasswordField('Password', 'Enter your password', _passwordController, showPassword, () => setState(() => showPassword = !showPassword)),
                                
                                SizedBox(height: isSmallScreen ? 18 : 20),
                                
                                // Confirm Password Field
                                _buildPasswordField('Confirm Password', 'Confirm your password', _confirmPasswordController, showConfirmPassword, () => setState(() => showConfirmPassword = !showConfirmPassword)),
                                
                                SizedBox(height: isSmallScreen ? 20 : 24),
                                
                                // Terms & Conditions
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: acceptTerms,
                                        onChanged: (value) => setState(() => acceptTerms = value!),
                                        activeColor: userConfig['color'],
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                color: userConfig['color'],
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: userConfig['color'],
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: isSmallScreen ? 28 : 32),
                                
                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: isSmallScreen ? 52 : 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: userConfig['gradient'],
                                      stops: const [0.0, 0.3, 0.7, 1.0],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: userConfig['color'].withOpacity(0.5),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                        spreadRadius: -3,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: (isLoading || !acceptTerms) ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.25),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.person_add,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                
                                SizedBox(height: isSmallScreen ? 24 : 28),
                                
                                // Sign In Link
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Already have an account? ",
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign in',
                                          style: TextStyle(
                                            color: userConfig['color'],
                                            fontWeight: FontWeight.w800,
                                            decoration: TextDecoration.underline,
                                            decorationColor: userConfig['color'].withOpacity(0.6),
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Error Message
                                if (error.isNotEmpty) ...[
                                  SizedBox(height: isSmallScreen ? 18 : 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFECACA),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFDC2626),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            error,
                                            style: const TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                SizedBox(height: isSmallScreen ? 16 : 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isSmallScreen ? 16 : 18,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, String hint, TextEditingController controller, bool showPassword, VoidCallback toggleVisibility) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: !showPassword,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isSmallScreen ? 16 : 18,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              suffixIcon: GestureDetector(
                onTap: toggleVisibility,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
  setState(() => error = ''); // Clear previous error messages

  // --- Validation Logic ---
  if (_fullNameController.text.isEmpty ||
      _emailController.text.isEmpty ||
      _phoneController.text.isEmpty ||
      _addressController.text.isEmpty ||
      _passwordController.text.isEmpty ||
      _confirmPasswordController.text.isEmpty) {
    _showSnackBar('All fields are required.', isError: true);
    return;
  }

  if (_passwordController.text != _confirmPasswordController.text) {
    _showSnackBar('Passwords do not match.', isError: true);
    return;
  }

  if (_passwordController.text.length < 6) {
    _showSnackBar('Password must be at least 6 characters long.', isError: true);
    return;
  }

  // --- Added Email Validation ---
  bool isEmailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_emailController.text.trim());
  if (!isEmailValid) {
    _showSnackBar('Please enter a valid email address.', isError: true);
    return;
  }

  if (!acceptTerms) {
    _showSnackBar('You must accept the Terms & Conditions.', isError: true);
    return;
  }
  
  setState(() => isLoading = true);

  try {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final userId = userCredential.user?.uid;
    if (userId != null) {
      final usersCollection = FirebaseFirestore.instance.collection('users');
      await usersCollection.doc(userId).set({
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Registration successful! Welcome.', isError: false);
      
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

  } on FirebaseAuthException catch (e) {
    String message;
    if (e.code == 'weak-password') {
      message = 'The password provided is too weak.';
    } else if (e.code == 'email-already-in-use') {
      message = 'The account already exists for that email.';
    } else {
      message = 'Registration failed: ${e.message}';
    }
    _showSnackBar(message, isError: true);
    setState(() {
      error = message;
    });
  } catch (e) {
    _showSnackBar('An unknown error occurred.', isError: true);
    setState(() {
      error = e.toString();
    });
  } finally {
    setState(() => isLoading = false);
  }
}
}