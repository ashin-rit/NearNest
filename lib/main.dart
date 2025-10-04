import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

// Import splash screen
import 'package:nearnest/screens/splash_screen.dart';

// Import the new landing page and separate login pages
import 'package:nearnest/screens/landing_page.dart';
import 'package:nearnest/screens/login/admin_login_page.dart';
import 'package:nearnest/screens/login/customer_login_page.dart';
import 'package:nearnest/screens/login/service_provider_login_page.dart';
import 'package:nearnest/screens/login/shop_login_page.dart';

// Keep your existing registration pages
import 'package:nearnest/screens/register/customer_register.dart';
import 'package:nearnest/screens/register/service_provider_register.dart';
import 'package:nearnest/screens/register/shop_register.dart';

// Keep your existing cart and checkout functionality
import 'package:nearnest/screens/cart_screen.dart';
import 'package:nearnest/screens/checkout_screen.dart';
import 'package:nearnest/services/shopping_cart_service.dart';

// Import notification channel setup
import 'package:nearnest/services/notification_channel_setup.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification channel for Android 8.0+
  await NotificationChannelSetup.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ShoppingCartService()),
      ],
      child: MaterialApp(
        title: 'NearNest - Connect with Local Services',
        // Changed home to SplashScreen
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          // Add splash screen route
          '/splash': (context) => const SplashScreen(),
          
          // New landing and login routes
          '/landing': (context) => const LandingPage(),
          '/admin-login': (context) => const AdminLoginPage(),
          '/customer-login': (context) => const CustomerLoginPage(),
          '/service-provider-login': (context) => const ServiceProviderLoginPage(),
          '/shop-login': (context) => const ShopLoginPage(),
          
          // Keep your existing registration routes
          '/customer_registration': (context) => const CustomerRegisterPage(),
          '/services_registration': (context) => const ServiceProviderRegisterPage(),
          '/shop_registration': (context) => const ShopsRegisterPage(),
          
          // Keep your existing cart and checkout routes
          '/cart_screen': (context) => const CartScreen(),
          '/checkout_screen': (context) => const CheckoutScreen(),
        },
        
        // Handle route generation for better navigation
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/splash':
              return _createRoute(const SplashScreen());
            case '/landing':
              return _createRoute(const LandingPage());
            case '/admin-login':
              return _createRoute(const AdminLoginPage());
            case '/customer-login':
              return _createRoute(const CustomerLoginPage());
            case '/service-provider-login':
              return _createRoute(const ServiceProviderLoginPage());
            case '/shop-login':
              return _createRoute(const ShopLoginPage());
            default:
              return null;
          }
        },
        
        // Handle unknown routes
        onUnknownRoute: (RouteSettings settings) {
          return _createRoute(
            Scaffold(
              appBar: AppBar(
                title: const Text('Page Not Found'),
                backgroundColor: const Color(0xFF667EEA),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Page not found!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to create smooth page transitions
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}