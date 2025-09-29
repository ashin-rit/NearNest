// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:nearnest/screens/landing_page.dart';
import 'package:nearnest/screens/login/admin_login_page.dart';
import 'package:nearnest/screens/login/customer_login_page.dart';
import 'package:nearnest/screens/login/service_provider_login_page.dart';
import 'package:nearnest/screens/login/shop_login_page.dart';
// Import your existing registration pages here
import 'package:nearnest/screens/register/customer_register.dart';
import 'package:nearnest/screens/register/service_provider_register.dart';
import 'package:nearnest/screens/register/shop_register.dart';

class AppRoutes {
  static const String landing = '/landing';
  static const String adminLogin = '/admin-login';
  static const String customerLogin = '/customer-login';
  static const String serviceProviderLogin = '/service-provider-login';
  static const String shopLogin = '/shop-login';
  static const String customerRegistration = '/customer_registration';
  static const String serviceProviderRegistration = '/services_registration';
  static const String shopRegistration = '/shop_registration';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      landing: (context) => const LandingPage(),
      adminLogin: (context) => const AdminLoginPage(),
      customerLogin: (context) => const CustomerLoginPage(),
      serviceProviderLogin: (context) => const ServiceProviderLoginPage(),
      shopLogin: (context) => const ShopLoginPage(),
      customerRegistration: (context) => const CustomerRegisterPage(),
      serviceProviderRegistration: (context) => const ServiceProviderRegisterPage(),
      shopRegistration: (context) => const ShopsRegisterPage(),
    };
  }

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (context) => const LandingPage());
      case adminLogin:
        return MaterialPageRoute(builder: (context) => const AdminLoginPage());
      case customerLogin:
        return MaterialPageRoute(builder: (context) => const CustomerLoginPage());
      case serviceProviderLogin:
        return MaterialPageRoute(builder: (context) => const ServiceProviderLoginPage());
      case shopLogin:
        return MaterialPageRoute(builder: (context) => const ShopLoginPage());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(
              child: Text('Page not found!'),
            ),
          ),
        );
    }
  }
}