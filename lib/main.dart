import 'package:flutter/material.dart';
import 'package:nearnest/screens/login_page.dart';
import 'package:nearnest/screens/register/admin_register.dart';
import 'package:nearnest/screens/register/customer_register.dart';
import 'package:nearnest/screens/register/service_provider_register.dart';
import 'package:nearnest/screens/register/shop_register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// New Imports for cart and checkout features
import 'package:nearnest/screens/cart_screen.dart';
import 'package:nearnest/screens/checkout_screen.dart';
import 'package:nearnest/services/shopping_cart_service.dart';
import 'package:provider/provider.dart';

void main() async {
  // Ensure that Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        title: 'Professional Multi-User Login',
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'SF Pro Display',
        ),
        routes: {
          '/admin_registration': (context) => const AdminRegisterPage(),
          '/customer_registration': (context) => const CustomerRegisterPage(),
          '/services_registration': (context) => const ServiceProviderRegisterPage(),
          '/shops_registration': (context) => const ShopsRegisterPage(),
          // New routes for cart and checkout
          '/cart_screen': (context) => const CartScreen(),
          '/checkout_screen': (context) => const CheckoutScreen(),
        },
      ),
    );
  }
}