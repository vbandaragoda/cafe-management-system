import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

/// The 5-tab bottom nav from the Figma mobile frames: Home / Menu /
/// Cart / Orders / Profile. Cart and Orders are visible to everyone
/// but redirect guests to sign in when tapped (registered-user-only
/// functionality), matching the assignment's role-gating requirement.
class CafforaBottomNav extends StatelessWidget {
  final int currentIndex;
  const CafforaBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.menu,
    AppRoutes.cart,
    AppRoutes.orders,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index, auth),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }

  void _onTap(BuildContext context, int index, AuthProvider auth) {
    if (index == currentIndex) return;
    final needsAuth = index == 2 || index == 3; // Cart, Orders
    if (needsAuth && !auth.isAuthenticated) {
      Navigator.of(context).pushNamed(AppRoutes.auth);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(_routes[index], (route) => false);
  }
}
