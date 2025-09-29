// lib/screens/login/service_provider_login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/screens/awaiting_approval_page.dart';
import 'package:nearnest/screens/common_widgets.dart';
import 'package:nearnest/services/auth_service.dart';
import 'package:nearnest/screens/dashboards/service_provider_dashboard.dart';

class ServiceProviderLoginPage extends StatefulWidget {
  const ServiceProviderLoginPage({super.key});

  @override
  _ServiceProviderLoginPageState createState() => _ServiceProviderLoginPageState();
}

class _ServiceProviderLoginPageState extends State<ServiceProviderLoginPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool isLoading = false;
  bool showPassword = false;

  // Enhanced service provider color palette
  final List<Color> gradientColors = [
    const Color(0xFF0F172A), // Dark blue
    const Color(0xFF1E293B), // Slate
    const Color(0xFF0EA5E9), // Sky blue
    const Color(0xFF38BDF8), // Light blue
  ];
  final Color primaryColor = const Color(0xFF0EA5E9);
  final Color accentColor = const Color(0xFF38BDF8);

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
    _emailController.dispose();
    _passwordController.dispose();
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
          : primaryColor.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 8,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Business email is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userUid = userCredential.user?.uid;
      if (userUid != null) {
        final userDoc = await _authService.getUserDataByUid(userUid);

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final role = userData['role'];
          final status = userData['status'] ?? 'pending';

          if (role != 'Services') {
            await _authService.signOut();
            _showSnackBar('Access denied. Please use the correct login page for your role.', isError: true);
            return;
          }

          if (status == 'pending') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const AwaitingApprovalPage(),
              ),
            );
            return;
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ServiceProviderDashboard(),
            ),
          );
          _showSnackBar('Welcome back to your service dashboard!', isError: false);
        } else {
          await _authService.signOut();
          _showSnackBar('Service provider data not found. Please contact support.', isError: true);
        }
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } catch (e) {
      _showSnackBar('An unknown error occurred. Please try again.', isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        message = 'Invalid email or password.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'user-disabled':
        message = 'Your service provider account has been disabled. Please contact support.';
        break;
      case 'too-many-requests':
        message = 'Too many login attempts. Please try again later.';
        break;
      default:
        message = e.message ?? 'Authentication failed. Please try again.';
    }
    _showSnackBar(message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background with professional gradient
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
          
          // Professional floating shapes
          ...List.generate(6, (index) => _buildProfessionalShape(index)),
          
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
                      SizedBox(height: size.height * 0.05),
                      _buildProfessionalHeader(),
                      SizedBox(height: size.height * 0.05),
                      _buildProfessionalLoginForm(),
                      SizedBox(height: size.height * 0.03),
                      _buildSocialLoginButtons(),
                      SizedBox(height: size.height * 0.02),
                      _buildFooter(),
                      SizedBox(height: size.height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildProfessionalShape(int index) {
    final icons = [
      Icons.business_center_rounded,
      Icons.engineering_rounded,
      Icons.handyman_rounded,
      Icons.design_services_rounded,
      Icons.construction_rounded,
      Icons.psychology_rounded,
    ];
    
    final random = (index * 149) % 100;
    final left = (random / 100) * MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: 90 + (index * 85.0),
          child: Transform.scale(
            scale: 0.4 + (_pulseAnimation.value * 0.3),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icons[index],
                color: Colors.white.withOpacity(0.4),
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Professional briefcase with glow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(0.8),
                        accentColor.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        spreadRadius: 10,
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: const Text(
              'Service Provider',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.work_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Grow Your Professional Business',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalLoginForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernTextField(
                  controller: _emailController,
                  hint: 'Business Email Address',
                  icon: Icons.email_rounded,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  validator: _validatePassword,
                  isPassword: true,
                ),
                const SizedBox(height: 32),
                _buildEnhancedLoginButton(),
                const SizedBox(height: 20),
                _buildForgotPasswordLink(),
                const SizedBox(height: 16),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: isPassword ? !showPassword : false,
        style: const TextStyle(
          fontSize: 16,
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
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildEnhancedLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isLoading 
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : [primaryColor, accentColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isLoading) BoxShadow(
            color: primaryColor.withOpacity(0.4),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                    'Signing In...',
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
                  const Icon(Icons.business_center_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Access Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  'LinkedIn',
                  Icons.business,
                  const Color(0xFF0077B5),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  'Google',
                  Icons.g_mobiledata,
                  Colors.white,
                  Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String text, IconData icon, Color bgColor, Color textColor) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () {
          _showSnackBar('Professional login coming soon!', isError: false);
        },
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: textColor),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: isLoading ? null : () {
        _showSnackBar('Reset password link sent to email!', isError: false);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: const Text(
        'Forgot your password?',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: isLoading ? null : () {
          Navigator.of(context).pushNamed('/services_registration');
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "New service provider? ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
            ),
            children: [
              TextSpan(
                text: 'Join Platform',
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
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TextButton.icon(
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
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
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
              CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Accessing your dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}