import 'package:flutter/material.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Multi-User Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      // Define routes for different registration pages

    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> users = [
    {
      'username': 'admin@example.com',
      'password': 'admin123',
      'role': 'Admin',
      'color': Color(0xFF1E3A8A),
      'gradient': [
        Color(0xFF3B82F6),
        Color(0xFF2563EB),
        Color(0xFF1E40AF),
        Color(0xFF1E3A8A),
      ],
      'icon': Icons.admin_panel_settings,
      'title': 'Admin Portal',
      'subtitle': 'Manage system and users',
      'inputLabel': 'Admin ID',
      'inputHint': 'Enter your admin ID',
      'registrationRoute': '/admin_registration',
      'signupText': 'Register as Admin'
    },
    {
      'username': 'customer@example.com',
      'password': 'customer123',
      'role': 'Customer',
      'color': Color(0xFF065F46),
      'gradient': [
        Color(0xFF34D399),
        Color(0xFF10B981),
        Color(0xFF059669),
        Color(0xFF047857),
      ],
      'icon': Icons.people,
      'title': 'Welcome Back',
      'subtitle': 'Browse and purchase services',
      'inputLabel': 'User Email',
      'inputHint': 'Enter your email address',
      'registrationRoute': '/customer_registration',
      'signupText': 'Create Account'
    },
    {
      'username': 'service@example.com',
      'password': 'service123',
      'role': 'Service Provider',
      'color': Color(0xFF7C2D12),
      'gradient': [
        Color(0xFFF97316),
        Color(0xFFEA580C),
        Color(0xFFDC2626),
        Color(0xFFB91C1C),
      ],
      'icon': Icons.assignment_ind,
      'title': 'Service Provider',
      'subtitle': 'Manage your services',
      'inputLabel': 'Provider ID',
      'inputHint': 'Enter your service provider ID',
      'registrationRoute': '/service_provider_registration',
      'signupText': 'Register as Provider'
    },
    {
      'username': 'shop@example.com',
      'password': 'shop123',
      'role': 'Shops',
      'color': Color(0xFF581C87),
      'gradient': [
        Color(0xFFA855F7),
        Color(0xFF9333EA),
        Color(0xFF7C3AED),
        Color(0xFF6D28D9),
      ],
      'icon': Icons.storefront,
      'title': 'Shop Management',
      'subtitle': 'Manage your store',
      'inputLabel': 'Shop ID',
      'inputHint': 'Enter your shop ID',
      'registrationRoute': '/shop_registration',
      'signupText': 'Register Shop'
    },
  ];

  int selectedIndex = 1;
  String email = '';
  String password = '';
  String error = '';
  bool isLoading = false;
  bool showPassword = false;
  bool rememberMe = false;

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
    final currentUser = users[selectedIndex];
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
                  currentUser['color'].withOpacity(0.12),
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
                          color: currentUser['color'].withOpacity(0.15),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                          spreadRadius: -6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Section - More compact
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
                              colors: currentUser['gradient'],
                              stops: [0.0, 0.3, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentUser['color'].withOpacity(0.4),
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
                                  currentUser['icon'],
                                  color: Colors.white,
                                  size: isSmallScreen ? 28 : 32,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              Text(
                                currentUser['title'],
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 26 : 30,
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
                                currentUser['subtitle'],
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
                        
                        // Role Selection Icons - Horizontal small icons
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: users.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> user = entry.value;
                              bool isSelected = selectedIndex == index;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                    email = '';
                                    password = '';
                                    error = '';
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 350),
                                  curve: Curves.easeInOutCubic,
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? user['color'].withOpacity(0.15)
                                        : Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                          ? user['color'].withOpacity(0.6)
                                          : Color(0xFFE2E8F0),
                                      width: isSelected ? 2.0 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: user['color'].withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                              spreadRadius: -2,
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Container(
                                    width: isSmallScreen ? 36 : 40,
                                    height: isSmallScreen ? 36 : 40,
                                    decoration: isSelected
                                        ? BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                user['gradient'][0],
                                                user['gradient'][2],
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: user['color'].withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          )
                                        : BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                          ),
                                    child: Icon(
                                      user['icon'],
                                      color: isSelected 
                                          ? Colors.white
                                          : Color(0xFF64748B),
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        
                        // Login Form
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: isSmallScreen ? 16 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dynamic Email/ID Field
                              Text(
                                currentUser['inputLabel'],
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
                                  key: ValueKey('email_$selectedIndex'),
                                  decoration: InputDecoration(
                                    hintText: currentUser['inputHint'],
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: isSmallScreen ? 16 : 18,
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
                                  onChanged: (value) => email = value,
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 20 : 24),
                              
                              // Password Field
                              Text(
                                'Password',
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
                                  key: ValueKey('password_$selectedIndex'),
                                  obscureText: !showPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: isSmallScreen ? 16 : 18,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() => showPassword = !showPassword),
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
                                  onChanged: (value) => password = value,
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 20 : 24),
                              
                              // Remember Me & Forgot Password
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: rememberMe,
                                          onChanged: (value) => setState(() => rememberMe = value!),
                                          activeColor: currentUser['color'],
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      _handleForgotPassword(currentUser);
                                    },
                                    child: Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: currentUser['color'],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: currentUser['color'].withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: isSmallScreen ? 28 : 32),
                              
                              // Login Button
                              Container(
                                width: double.infinity,
                                height: isSmallScreen ? 52 : 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: currentUser['gradient'],
                                    stops: [0.0, 0.3, 0.7, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: currentUser['color'].withOpacity(0.5),
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
                                  onPressed: isLoading ? null : _handleLogin,
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
                                                Icons.login,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Sign In',
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
                              
                              // Sign Up Link - Now Clickable and Role-specific
                              Center(
                                child: GestureDetector(
                                  onTap: () => _navigateToRegistration(currentUser),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: currentUser['signupText'],
                                          style: TextStyle(
                                            color: currentUser['color'],
                                            fontWeight: FontWeight.w800,
                                            decoration: TextDecoration.underline,
                                            decorationColor: currentUser['color'].withOpacity(0.6),
                                            decorationThickness: 2,
                                          ),
                                        ),
                                      ],
                                    ),
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

  void _navigateToRegistration(Map<String, dynamic> user) {
    Navigator.pushNamed(context, user['registrationRoute']);
  }

  void _handleForgotPassword(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: user['color']),
            SizedBox(width: 10),
            Text('Forgot Password'),
          ],
        ),
        content: Text('Password recovery for ${user['role']} accounts will be sent to your registered contact information.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: user['color']),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password recovery instructions sent!'),
                  backgroundColor: user['color'],
                ),
              );
            },
            child: Text('Send Recovery', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(milliseconds: 1500));

    final user = users[selectedIndex];
    
    setState(() => isLoading = false);

    if (email == user['username'] && password == user['password']) {
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
                    color: user['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: user['color'].withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: user['color'].withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: user['color'],
                    size: 32,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome ${user['role']}!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'You have successfully logged in to your account',
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
                      colors: user['gradient'],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: user['color'].withOpacity(0.4),
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
    } else {
      setState(() => error = 'Invalid credentials. Please check your ${users[selectedIndex]['inputLabel'].toLowerCase()} and password.');
    }
  }
}

