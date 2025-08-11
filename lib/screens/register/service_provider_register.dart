import 'package:flutter/material.dart';

class ServiceProviderRegisterPage extends StatefulWidget {
  const ServiceProviderRegisterPage({super.key});

  @override
  _ServiceProviderRegisterPageState createState() => _ServiceProviderRegisterPageState();
}

class _ServiceProviderRegisterPageState extends State<ServiceProviderRegisterPage> with TickerProviderStateMixin {
  final Map<String, dynamic> userConfig = {
    'role': 'Service Provider',
    'color': Color(0xFF7C2D12),
    'gradient': [
      Color(0xFFF97316),
      Color(0xFFEA580C),
      Color(0xFFDC2626),
      Color(0xFFB91C1C),
    ],
    'icon': Icons.assignment_ind,
    'title': 'Service Provider Registration',
    'subtitle': 'Join as a service partner'
  };

  String fullName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phoneNumber = '';
  String businessName = '';
  String serviceType = '';
  String licenseNumber = '';
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
      duration: Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
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
                  Color(0xFFF1F5F9).withOpacity(0.8),
                  Color(0xFFFFFFFF),
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
                          offset: Offset(0, 16),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: userConfig['color'].withOpacity(0.15),
                          blurRadius: 24,
                          offset: Offset(0, 8),
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
                              stops: [0.0, 0.3, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: userConfig['color'].withOpacity(0.4),
                                blurRadius: 20,
                                offset: Offset(0, 10),
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
                                      offset: Offset(0, 8),
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
                                  fontSize: isSmallScreen ? 24 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
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
                                      offset: Offset(0, 1),
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
                              _buildTextField('Full Name', 'Enter your full name', 
                                  (value) => fullName = value, Icons.person_outline),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Email Field
                              _buildTextField('Email Address', 'Enter your email', 
                                  (value) => email = value, Icons.email_outlined),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Business Name Field
                              _buildTextField('Business Name', 'Enter your business name', 
                                  (value) => businessName = value, Icons.business_outlined),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Service Type Field
                              _buildTextField('Service Type', 'Enter type of service', 
                                  (value) => serviceType = value, Icons.work_outline),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Phone Number Field
                              _buildTextField('Phone Number', 'Enter your phone number', 
                                  (value) => phoneNumber = value, Icons.phone_outlined),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // License Number Field
                              _buildTextField('License Number', 'Enter license/registration number', 
                                  (value) => licenseNumber = value, Icons.verified_outlined),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Password Field
                              _buildPasswordField('Password', 'Enter your password', 
                                  (value) => password = value, showPassword, () => setState(() => showPassword = !showPassword)),
                              
                              SizedBox(height: isSmallScreen ? 18 : 20),
                              
                              // Confirm Password Field
                              _buildPasswordField('Confirm Password', 'Confirm your password', 
                                  (value) => confirmPassword = value, showConfirmPassword, () => setState(() => showConfirmPassword = !showConfirmPassword)),
                              
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
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'I agree to the ',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Service Provider Terms',
                                            style: TextStyle(
                                              color: userConfig['color'],
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
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
                                    stops: [0.0, 0.3, 0.7, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: userConfig['color'].withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: Offset(0, 10),
                                      spreadRadius: -3,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
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
                                      ? SizedBox(
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
                                              padding: EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.business_center,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Register as Provider',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.3),
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
                                    style: TextStyle(
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
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFFFECACA),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFFECACA),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          color: Color(0xFFDC2626),
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: TextStyle(
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
    );
  }

  Widget _buildTextField(String label, String hint, Function(String) onChanged, IconData icon) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isSmallScreen ? 16 : 18,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, String hint, Function(String) onChanged, bool showPassword, VoidCallback toggleVisibility) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            obscureText: !showPassword,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isSmallScreen ? 16 : 18,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.lock_outline,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
              suffixIcon: GestureDetector(
                onTap: toggleVisibility,
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ),
              hintStyle: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);
    await Future.delayed(Duration(milliseconds: 1500));
    setState(() => isLoading = false);

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: userConfig['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: userConfig['color'].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: userConfig['color'].withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle,
                  color: userConfig['color'],
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Welcome Service Provider!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your service provider account is under review. You will be notified once approved.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: userConfig['gradient'],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: userConfig['color'].withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || 
        phoneNumber.isEmpty || businessName.isEmpty || serviceType.isEmpty || licenseNumber.isEmpty) {
      setState(() => error = 'All fields are required');
      return false;
    }

    if (password != confirmPassword) {
      setState(() => error = 'Passwords do not match');
      return false;
    }

    if (password.length < 6) {
      setState(() => error = 'Password must be at least 6 characters');
      return false;
    }

    if (!email.contains('@')) {
      setState(() => error = 'Please enter a valid email address');
      return false;
    }

    setState(() => error = '');
    return true;
  }
}