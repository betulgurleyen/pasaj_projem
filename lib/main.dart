import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'app_styles.dart';
import 'add_product_screen.dart';
import 'admin_screen.dart';
import 'reports_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppStyles.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/add_product': (context) => AddProductScreen(),
        '/admin': (context) => const AdminScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/orders': (context) => const OrdersScreen(),
      },
    ),
  );
}
