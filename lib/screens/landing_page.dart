// Enhanced Landing Page with 2x2 Grid Card Flip
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Track which cards are flipped
  Set<int> flippedCards = {};

  final List<Color> gradientColors = [
    const Color(0xFF2D1B69),
    const Color(0xFF11998E),
    const Color(0xFF38EF7D),
    const Color(0xFFFFC837),
  ];

  final List<Map<String, dynamic>> roles = [
    {
      'id': 0,
      'role': 'Admin',
      'title': 'Administrator',
      'description': 'Secure platform management',
      'icon': Icons.admin_panel_settings_rounded,
      'loginRoute': '/admin-login',
      'registerRoute': null, // No registration for admin
      'colors': [const Color(0xFF7C2D12), const Color(0xFFDC2626)],
      'primaryColor': const Color(0xFF7C2D12),
      'primaryCta': 'Contact Admin',
      'secondaryCta': 'Sign In',
    },
    {
      'id': 1,
      'role': 'Customer',
      'title': 'Customer',
      'description': 'Find & book amazing services',
      'icon': Icons.people_alt_rounded,
      'loginRoute': '/customer-login',
      'registerRoute': '/customer_registration',
      'colors': [const Color(0xFF06D6A0), const Color(0xFF118AB2)],
      'primaryColor': const Color(0xFF06D6A0),
      'primaryCta': 'Register',
      'secondaryCta': 'Login',
    },
    {
      'id': 2,
      'role': 'Services',
      'title': 'Service Provider',
      'description': 'Offer professional services',
      'icon': Icons.business_center_rounded,
      'loginRoute': '/service-provider-login',
      'registerRoute': '/services_registration',
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
      'primaryColor': const Color(0xFF0EA5E9),
      'primaryCta': 'Register',
      'secondaryCta': 'Login',
    },
    {
      'id': 3,
      'role': 'Shops',
      'title': 'Shop Owner',
      'description': 'Manage your shop & products',
      'icon': Icons.storefront_rounded,
      'loginRoute': '/shop-login',
      'registerRoute': '/shop_registration',
      'colors': [const Color(0xFF92400E), const Color(0xFFF59E0B)],
      'primaryColor': const Color(0xFF92400E),
      'primaryCta': 'Register',
      'secondaryCta': 'Login',
    },
  ];

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
    super.dispose();
  }

  void _toggleCardFlip(int cardId) {
    setState(() {
      if (flippedCards.contains(cardId)) {
        flippedCards.remove(cardId);
      } else {
        flippedCards.add(cardId);
      }
    });
    
    // Auto-flip back after 4 seconds for better UX
    if (flippedCards.contains(cardId)) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && flippedCards.contains(cardId)) {
          setState(() {
            flippedCards.remove(cardId);
          });
        }
      });
    }
  }

  void _handleNavigation(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white, // Simple white background
      body: Stack(
        children: [
          // Floating shapes on white background
          ...List.generate(6, (index) => _buildFloatingShape(index)),
          
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
                      _buildEnhancedHeader(),
                      SizedBox(height: size.height * 0.06),
                      _build2x2FlipCards(),
                      SizedBox(height: size.height * 0.04),
                      _buildInstructions(),
                      SizedBox(height: size.height * 0.02),
                      _buildFooter(),
                      SizedBox(height: size.height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    final icons = [
      Icons.home_rounded,
      Icons.star_rounded,
      Icons.location_on_rounded,
      Icons.local_offer_rounded,
      Icons.verified_rounded,
      Icons.trending_up_rounded,
    ];
    
    final random = (index * 137) % 100;
    final left = (random / 100) * MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: 80 + (index * 100.0),
          child: Transform.scale(
            scale: 0.3 + (_pulseAnimation.value * 0.2),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icons[index],
                color: Colors.grey.withOpacity(0.3),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Logo with simplified styling for white background
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
                        gradientColors[1].withOpacity(0.1),
                        gradientColors[1].withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradientColors[0], gradientColors[2]],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.home_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.black87, Colors.black54],
            ).createShader(bounds),
            child: const Text(
              'NearNest',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradientColors[1].withOpacity(0.15),
                  gradientColors[2].withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradientColors[1].withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.black87,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Connect with local services & shops',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
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

  Widget _build2x2FlipCards() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tap to Explore Roles',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 2x2 Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  return _buildFlipCard(roles[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipCard(Map<String, dynamic> role) {
    final isFlipped = flippedCards.contains(role['id']);
    
    return GestureDetector(
      onTap: () => _toggleCardFlip(role['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(isFlipped ? 3.14159 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: isFlipped 
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: _buildCardBack(role),
                )
              : _buildCardFront(role),
        ),
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> role) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: role['colors']),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: role['primaryColor'].withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              role['icon'],
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            role['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            role['description'],
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ready to start?',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: () => _handlePrimaryAction(role),
              style: ElevatedButton.styleFrom(
                backgroundColor: role['primaryColor'],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                role['primaryCta'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Secondary CTA Button
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: () => _handleNavigation(role['loginRoute']),
              style: OutlinedButton.styleFrom(
                foregroundColor: role['primaryColor'],
                side: BorderSide(color: role['primaryColor'], width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                role['secondaryCta'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrimaryAction(Map<String, dynamic> role) {
    if (role['role'] == 'Admin') {
      // For admin, primary action is "Contact Admin" - show contact info or dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact Administrator'),
          content: const Text('Please contact the system administrator to request admin access.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      // For other roles, primary action is "Register"
      _handleNavigation(role['registerRoute']);
    }
  }

  Widget _buildInstructions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 8),
            Text(
              'Cards auto-flip back after 4 seconds',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text(
                  'Need help? Contact our support team',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '© 2024 NearNest. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}