import 'package:flutter/material.dart';
import 'package:nearnest/screens/login_page.dart';
import 'package:nearnest/screens/register/admin_register.dart';
import 'package:nearnest/screens/register/customer_register.dart';
import 'package:nearnest/screens/register/service_provider_register.dart';
import 'package:nearnest/screens/register/shop_register.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
      routes: {
        '/admin_registration': (context) => const AdminRegisterPage(),
        '/customer_registration': (context) => const CustomerRegisterPage(),
        '/service_provider_registration': (context) => const ServiceProviderRegisterPage(),
        '/shop_registration': (context) => const ShopsRegisterPage(),
      },
    );
  }
}