import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/table/table_scan_screen.dart';
import 'constants.dart';

/// Central named-route table. Enforces the assignment's role-gating
/// rules in one place: Cart/Orders require a signed-in user (any
/// role), Admin screens require the ADMIN role specifically. Anything
/// else (Home, Menu, Auth) is reachable by guests.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings, BuildContext context) {
    final auth = context.read<AuthProvider>();

    Widget guardAuthenticated(Widget child) {
      if (!auth.isAuthenticated) return const AuthScreen();
      return child;
    }

    Widget guardAdmin(Widget child) {
      if (!auth.isAuthenticated) return const AuthScreen();
      if (!auth.isAdmin) {
        return const Scaffold(body: Center(child: Text('Admin access only.')));
      }
      return child;
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case AppRoutes.auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen(), settings: settings);
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen(), settings: settings);
      case AppRoutes.menu:
        return MaterialPageRoute(builder: (_) => const MenuScreen(), settings: settings);
      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => guardAuthenticated(const CartScreen()), settings: settings);
      case AppRoutes.orders:
        return MaterialPageRoute(builder: (_) => guardAuthenticated(const OrdersScreen()), settings: settings);
      case AppRoutes.orderDetail:
        final orderId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) => guardAuthenticated(OrderDetailScreen(orderId: orderId)), settings: settings);
      case AppRoutes.admin:
        return MaterialPageRoute(builder: (_) => guardAdmin(const AdminScreen()), settings: settings);
      case AppRoutes.tableScan:
        // Reachable by guests too — a customer may scan a table
        // before signing in; the lookup endpoint itself is public.
        return MaterialPageRoute(builder: (_) => const TableScanScreen(), settings: settings);
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen(), settings: settings);
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
    }
  }
}
