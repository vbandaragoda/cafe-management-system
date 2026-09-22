import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

/// Waits for AuthProvider to restore the saved session (or settle into
/// guest mode), then routes to Home. Kept intentionally brief so the
/// brand mark is on screen only as long as the async restore takes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceed());
  }

  Future<void> _proceed() async {
    final auth = context.read<AuthProvider>();
    var attempts = 0;
    while (auth.status == AuthStatus.unknown && attempts < 40) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Caffora', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Artisanal coffee, made for you', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
          ],
        ),
      ),
    );
  }
}
