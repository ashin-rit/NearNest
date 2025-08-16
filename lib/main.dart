import 'package:flutter/material.dart';
import 'package:nearnest/screens/login_page.dart';
import 'package:nearnest/screens/register/admin_register.dart';
import 'package:nearnest/screens/register/customer_register.dart';
import 'package:nearnest/screens/register/service_provider_register.dart';
import 'package:nearnest/screens/register/shop_register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
    return MaterialApp(
      title: 'Professional Multi-User Login',
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),

      // Define routes here in the main MaterialApp
      // lib/main.dart
      // ... inside the MaterialApp widget
      routes: {
        '/admin_registration': (context) => const AdminRegisterPage(),
        '/customer_registration': (context) => const CustomerRegisterPage(),
        '/service_provider_registration': (context) =>
            const ServiceProviderRegisterPage(),
        '/shops_registration': (context) => const ShopsRegisterPage(),
        // NOTE: The route name for Shops is '/shops_registration',
        // which is also a common place for a typo.
      },
    );
  }
}
