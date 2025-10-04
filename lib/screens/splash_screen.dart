import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearnest/services/one_signal_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();

    OneSignalService.initOneSignal(appId: 'b249d52c-38ff-4398-a34c-d160d7d2f795');

    // If user is already logged-in (persisted), save their playerId and set external ID
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save to Firestore
      OneSignalService.savePlayerIdToFirestoreForUid(user.uid);
      // Also set External ID inside OneSignal to unify subscriptions:
      OneSignalService.setExternalId(user.uid);
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        OneSignalService.setExternalId(user.uid);
        OneSignalService.savePlayerIdToFirestoreForUid(user.uid);
      } else {
        OneSignalService.logoutExternalId();
      }
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo fade in (0-0.8s)
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.53, curve: Curves.easeIn),
      ),
    );

    // Text fade in (0.8-1.5s)
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.53, 1.0, curve: Curves.easeIn),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/landing');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.35;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(logoSize * 0.22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(logoSize * 0.22),
                      child: Padding(
                        padding: EdgeInsets.all(logoSize * 0.16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.home_work_rounded,
                              size: logoSize * 0.55,
                              color: const Color(0xFF2196F3),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // Brand name and tagline
                Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'NearNest',
                        style: TextStyle(
                          fontSize: size.width * 0.07,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: size.height * 0.008),
                      Text(
                        'Your Local Marketplace',
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF666666),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
